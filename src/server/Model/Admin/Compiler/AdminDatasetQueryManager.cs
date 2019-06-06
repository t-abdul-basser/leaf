﻿// Copyright (c) 2019, UW Medicine Research IT, University of Washington
// Developed by Nic Dobbins and Cliff Spital, CRIO Sean Mooney
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
using System;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Extensions.Logging;
using System.Data.Common;
using Model.Results;
using Model.Validation;
using Model.Compiler;
using Model.Error;

namespace Model.Admin.Compiler
{
    public class AdminDatasetQueryManager
    {
        public interface IAdminDatasetQueryService
        {
            Task<AdminDatasetQuery> GetDatasetQueryByIdAsync(Guid id);
            Task<UpdateResult<AdminDatasetQuery>> UpdateDatasetQueryAsync(AdminDatasetQuery query);
        }

        readonly IAdminDatasetQueryService svc;
        readonly ILogger<AdminDatasetQueryManager> log;

        public AdminDatasetQueryManager(IAdminDatasetQueryService service,
            ILogger<AdminDatasetQueryManager> log)
        {
            svc = service;
            this.log = log;
        }

        public async Task<AdminDatasetQuery> GetDatasetQueryAsync(Guid id)
        {
            log.LogInformation("Getting DatasetQuery. Id:{Id}", id);
            return await svc.GetDatasetQueryByIdAsync(id);
        }

        public async Task<UpdateResult<AdminDatasetQuery>> UpdateDatasetQueryAsync(AdminDatasetQuery query)
        {
            ThrowIfInvalid(query);

            try
            {
                var result = await svc.UpdateDatasetQueryAsync(query);
                log.LogInformation("Updated DatasetQuery. DatasetQuery:{@DatasetQuery}", result.New);
                return result;
            }
            catch (DbException db)
            {
                log.LogError("Failed to update DatasetQuery. Query:{@Query} Code:{Code} Error:{Error}", query, db.ErrorCode, db.Message);
                db.MapThrow();
                throw;
            }
        }

        void ThrowIfInvalid(AdminDatasetQuery query)
        {
            Ensure.NotNull(query, nameof(query));
            Ensure.NotDefault(query.Id, nameof(query.Id));
            Ensure.Defined<Shape>(query.Shape, nameof(query.Shape));
            Ensure.NotNullOrWhitespace(query.Name, nameof(query.Name));
            Ensure.NotNullOrWhitespace(query.SqlStatement, nameof(query.SqlStatement));
        }
    }
}
