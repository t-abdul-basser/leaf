﻿// Copyright (c) 2019, UW Medicine Research IT, University of Washington
// Developed by Nic Dobbins and Cliff Spital, CRIO Sean Mooney
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
using System;
using System.Data.SqlClient;
using System.Data;
using System.Collections.Generic;
using System.Linq;
using Dapper;
using Model.Options;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.Logging;
using System.Security.Claims;
using System.Threading.Tasks;
using Services.Extensions;
using Model.Cohort;
using Services.Cohort;
using Services.Authorization;
using Model.Authorization;

namespace Services.Cohort
{
    public class CohortCacheService : CohortCounter.ICohortCacheService
    {
        const string queryCreateUnsaved = "app.sp_CreateCachedUnsavedQuery";
        const string queryDeleteUnsavedNonce = "app.sp_DeleteCachedUnsavedQuery";

        readonly AppDbOptions dbOptions;
        readonly CohortOptions cohortOptions;

        public CohortCacheService(
            IOptions<AppDbOptions> appDbOptions,
            IOptions<CohortOptions> cohortOptions
        )
        {
            dbOptions = appDbOptions.Value;
            this.cohortOptions = cohortOptions.Value;
        }

        public async Task<Guid> CreateUnsavedQueryAsync(PatientCohort cohort, IUserContext user)
        {
            var nonce = NonceOrThrowIfNull(user);
            using (var cn = new SqlConnection(dbOptions.ConnectionString))
            {
                await cn.OpenAsync();

                var queryId = await cn.ExecuteScalarAsync<Guid>(
                    queryCreateUnsaved,
                    new { user = user.UUID, nonce },
                    commandType: CommandType.StoredProcedure,
                    commandTimeout: dbOptions.DefaultTimeout
                );

                if (cohort.Any() && cohort.Count <= cohortOptions.RowLimit)
                {
                    var cohortTable = new PatientCohortTable(queryId, cohort.SeasonedPatients(cohortOptions.ExportLimit, queryId));

                    using (var bc = new SqlBulkCopy(cn))
                    {
                        bc.DestinationTableName = PatientCohortTable.Table;

                        await bc.WriteToServerAsync(cohortTable.Rows);
                    }
                }

                return queryId;
            }
        }

        public async Task DeleteUnsavedCohortAsync(IUserContext user)
        {
            var nonce = NonceOrThrowIfNull(user);

            using (var cn = new SqlConnection(dbOptions.ConnectionString))
            {
                await cn.OpenAsync();

                await cn.ExecuteAsync(
                    queryDeleteUnsavedNonce,
                    new { user = user.UUID, nonce },
                    commandTimeout: dbOptions.DefaultTimeout,
                    commandType: CommandType.StoredProcedure
                );
            }
        }

        Guid NonceOrThrowIfNull(IUserContext user)
        {
            var nonce = user?.SessionNonce;
            if (!nonce.HasValue)
            {
                throw new ArgumentNullException(nameof(nonce));
            }
            return nonce.Value;
        }
    }
}
