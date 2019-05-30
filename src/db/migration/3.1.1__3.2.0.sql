-- Add ref.Version Table.
IF OBJECT_ID('ref.Version') IS NOT NULL
	DROP TABLE [ref].[Version]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ref].[Version](
	[Lock] [char](1) NOT NULL,
	[Version] [nvarchar](100) NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
ALTER TABLE [ref].[Version] ADD  CONSTRAINT [PK_Version] PRIMARY KEY CLUSTERED 
(
	[Lock] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [ref].[Version] ADD  CONSTRAINT [DF_Version_Lock]  DEFAULT ('X') FOR [Lock]
GO
ALTER TABLE [ref].[Version]  WITH CHECK ADD  CONSTRAINT [CK_Version_1] CHECK  (([Lock]='X'))
GO
ALTER TABLE [ref].[Version] CHECK CONSTRAINT [CK_Version_1]
GO

-- Update network sprocs.
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


IF OBJECT_ID('network.sp_UpdateEndpoint', 'P') IS NOT NULL
	DROP PROCEDURE [network].[sp_UpdateEndpoint]
GO

IF OBJECT_ID('adm.sp_UpdateEndpoint', 'P') IS NOT NULL
    DROP PROCEDURE [adm].[sp_UpdateEndpoint];
GO

-- =============================================
-- Author:		Cliff Spital
-- Create date: 2019/5/28
-- Description:	Update the given network.Endpoint
-- =============================================
CREATE PROCEDURE [adm].[sp_UpdateEndpoint]
	@id int,
	@name nvarchar(200),
	@addr nvarchar(1000),
	@iss nvarchar(200),
	@kid nvarchar(200),
	@cert nvarchar(max),
    @isResponder bit,
    @isInterrogator bit,
    @user auth.[User]
AS
BEGIN
	SET NOCOUNT ON;

    IF (@id IS NULL)
		THROW 70400, N'NetworkEndpoint.Id is required.', 1;

	IF (@name IS NULL)
        THROW 70400, N'NetworkEndpoint.Name is required.', 1;
    
    IF (@addr IS NULL)
        THROW 70400, N'NetworkEndpoint.Address is required.', 1;
    
    IF (@iss IS NULL)
        THROW 70400, N'NetworkEndpoint.Issuer is required.', 1;
    
    IF (@kid IS NULL)
        THROW 70400, N'NetworkEndpoint.KeyId is required.', 1;
    
    IF (@cert IS NULL)
        THROW 70400, N'NetworkEndpoint.Certificate is required.', 1;
    
    IF (@isInterrogator IS NULL)
        THROW 70400, N'NetworkEndpoint.IsInterrogator is required.', 1;

    IF (@isResponder IS NULL)
        THROW 70400, N'NetworkEndpoint.IsResponder is required.', 1;

	BEGIN TRAN;

	IF NOT EXISTS (SELECT 1 FROM network.Endpoint WHERE Id = @id)
			THROW 70404, N'NetworkEndpoint not found.', 1;

	UPDATE network.Endpoint
	SET
		Name = @name,
		Address = @addr,
		Issuer = @iss,
		KeyId = @kid,
		Certificate = @cert,
		IsResponder = @isResponder,
		IsInterrogator = @isInterrogator,
        Updated = GETDATE()
	OUTPUT
		deleted.Id,
		deleted.Name,
		deleted.Address,
		deleted.Issuer,
		deleted.KeyId,
		deleted.Certificate,
		deleted.IsResponder,
		deleted.IsInterrogator,
		deleted.Updated,
		deleted.Created
	WHERE
		Id = @id;

	COMMIT;
END
GO


IF OBJECT_ID('adm.sp_UpsertIdentity', 'P') IS NOT NULL
    DROP PROCEDURE [adm].[sp_UpsertIdentity];
GO

-- =======================================
-- Author:      Cliff Spital
-- Create date: 2019/5/23
-- Description: Inserts or updates network.Identity.
-- =======================================
CREATE PROCEDURE [adm].[sp_UpsertIdentity]
    @name nvarchar(300),
    @abbr nvarchar(20),
    @desc nvarchar(4000),
    @totalPatients int,
    @lat DECIMAL(7,4),
    @lng DECIMAL(7,4),
    @primColor nvarchar(40),
    @secColor nvarchar(40),
    @user auth.[User]
AS
BEGIN
    SET NOCOUNT ON

    IF (@name IS NULL)
        THROW 70400, N'NetworkIdentity.Name is required.', 1;

    BEGIN TRAN;

    IF EXISTS (SELECT Lock FROM network.[Identity])
    BEGIN;
        UPDATE network.[Identity]
        SET
            [Name] = @name,
            Abbreviation = @abbr,
            [Description] = @desc,
            TotalPatients = @totalPatients,
            Latitude = @lat,
            Longitude = @lng,
            PrimaryColor = @primColor,
            SecondaryColor = @secColor
        OUTPUT
            deleted.Name,
            deleted.Abbreviation,
            deleted.[Description],
            deleted.TotalPatients,
            deleted.Latitude,
            deleted.Longitude,
            deleted.PrimaryColor,
            deleted.SecondaryColor;
    END;
    ELSE
    BEGIN;
        INSERT INTO network.[Identity] ([Name], Abbreviation, [Description], TotalPatients, Latitude, Longitude, PrimaryColor, SecondaryColor)
        OUTPUT NULL as [Name], NULL as Abbreviation, NULL as [Description], NULL as TotalPatients, NULL as Latitude, NULL as Longitude, NULL as PrimaryColor, NULL as SecondaryColor
        VALUES (@name, @abbr, @desc, @totalPatients, @lat, @lng, @primColor, @secColor);
    END;

    COMMIT;
END

GO


IF OBJECT_ID('adm.sp_CreateEndpoint', 'P') IS NOT NULL
    DROP PROCEDURE [adm].[sp_CreateEndpoint];
GO

-- =======================================
-- Author:      Cliff Spital
-- Create date: 2019/5/23
-- Description: Creates a new network.Endpoint
-- =======================================
CREATE PROCEDURE adm.sp_CreateEndpoint
    @name nvarchar(200),
    @addr nvarchar(1000),
    @iss nvarchar(200),
    @kid nvarchar(200),
    @cert nvarchar(max),
    @isInterrogator bit,
    @isResponder bit,
    @user auth.[User]
AS
BEGIN
    SET NOCOUNT ON

    IF (@name IS NULL)
        THROW 70400, N'NetworkEndpoint.Name is required.', 1;
    
    IF (@addr IS NULL)
        THROW 70400, N'NetworkEndpoint.Address is required.', 1;
    
    IF (@iss IS NULL)
        THROW 70400, N'NetworkEndpoint.Issuer is required.', 1;
    
    IF (@kid IS NULL)
        THROW 70400, N'NetworkEndpoint.KeyId is required.', 1;
    
    IF (@cert IS NULL)
        THROW 70400, N'NetworkEndpoint.Certificate is required.', 1;
    
    IF (@isInterrogator IS NULL)
        THROW 70400, N'NetworkEndpoint.IsInterrogator is required.', 1;

    IF (@isResponder IS NULL)
        THROW 70400, N'NetworkEndpoint.IsResponder is required.', 1;
    
    INSERT INTO network.Endpoint ([Name], [Address], Issuer, KeyId, [Certificate], Created, Updated, IsInterrogator, IsResponder)
    OUTPUT inserted.Id, inserted.Name, inserted.Address, inserted.Issuer, inserted.KeyId, inserted.Certificate, inserted.Created, inserted.Updated, inserted.IsInterrogator, inserted.IsResponder
    VALUES (@name, @addr, @iss, @kid, @cert, getdate(), getdate(), @isInterrogator, @isResponder);

END

GO


IF OBJECT_ID('adm.sp_DeleteEndpoint', 'P') IS NOT NULL
    DROP PROCEDURE [adm].[sp_DeleteEndpoint];
GO

-- =======================================
-- Author:      Cliff Spital
-- Create date: 2019/5/23
-- Description: Deletes a new network.Endpoint
-- =======================================
CREATE PROCEDURE adm.sp_DeleteEndpoint
    @id int,
	@user auth.[User]
AS
BEGIN
    SET NOCOUNT ON

    DELETE FROM network.Endpoint
    OUTPUT deleted.Id, deleted.Name, deleted.Address, deleted.Issuer, deleted.KeyId, deleted.Certificate, deleted.Created, deleted.Updated, deleted.IsInterrogator, deleted.IsResponder
    WHERE Id = @id;

END

GO

IF OBJECT_ID('app.sp_CalculatePatientCounts', 'P') IS NOT NULL
    DROP PROCEDURE [adm].[sp_DeleteEndpoint];
GO

-- =======================================
-- Author:      Nic Dobbins
-- Create date: 2019/5/23
-- Description: Loops through Concepts and auto-calculates patient counts.
-- =======================================
CREATE PROCEDURE [app].[sp_CalculatePatientCounts]

@PersonIdField NVARCHAR(50),
@TargetDataBaseName NVARCHAR(50),
@TotalAllowedRuntimeInMinutes INT,
@PerRootConceptAllowedRuntimeInMinutes INT,
@SpecificRootConcept UNIQUEIDENTIFIER = NULL

AS
BEGIN

	SELECT Id
		 , RowNumber = DENSE_RANK() OVER(ORDER BY Id)
	INTO #Roots
	FROM app.Concept
	WHERE IsRoot = 1
		  AND (Id = @SpecificRootConcept OR @SpecificRootConcept IS NULL)

	DECLARE @TotalRoots INT = (SELECT MAX(RowNumber) FROM #roots),
			@CurrentRoot INT = 1,
			@CurrentRootId UNIQUEIDENTIFIER,
			@TotalConcepts INT,
			@CurrentConcept INT = 1,
			@CurrentConceptId UNIQUEIDENTIFIER,
			@From NVARCHAR(MAX),
			@Where NVARCHAR(MAX),
			@Date NVARCHAR(200),
			@isEncounterBased BIT,
			@SetMarker NVARCHAR(5) = '@',
			@SetAlias NVARCHAR(5) = '_T',
			@TimeLimit DATETIME = DATEADD(MINUTE,@TotalAllowedRuntimeInMinutes,GETDATE()),
			@TimeLimitPerRootConcept DATETIME = DATEADD(MINUTE,@PerRootConceptAllowedRuntimeInMinutes,GETDATE()),
			@PerRootConceptRowLimit INT = 50000,
			@CurrentDateTime DATETIME = GETDATE()
	

	------------------------------------------------------------------------------------------------------------------------------ 
	-- ForEach root concept
	------------------------------------------------------------------------------------------------------------------------------
	WHILE @CurrentRoot <= @TotalRoots AND @CurrentDateTime < @TimeLimit

	BEGIN
		
		SET @CurrentRootId = (SELECT Id FROM #roots WHERE RowNumber = @CurrentRoot)

		BEGIN TRY DROP TABLE #Concepts END TRY BEGIN CATCH END CATCH

		-- Find all children concepts under current root concept
		SELECT TOP (@PerRootConceptRowLimit)
			   c.Id
			 , SqlSetFrom = REPLACE(s.SqlSetFrom,@SetMarker,@SetAlias)
			 , SqlSetWhere = REPLACE(c.SqlSetWhere,@SetMarker,@SetAlias)
			 , SqlFieldDate = REPLACE(s.SqlFieldDate,@SetMarker,@SetAlias)
			 , isEncounterBased
			 , RowNumber = DENSE_RANK() OVER(ORDER BY PatientCountLastUpdateDateTime,c.Id)
		INTO #Concepts
		FROM app.Concept AS c
			 LEFT JOIN app.ConceptSqlSet AS s
				ON c.SqlSetId = s.Id
		WHERE c.RootId = @CurrentRootId
			  AND c.IsPatientCountAutoCalculated = 1
		ORDER BY PatientCountLastUpdateDateTime ASC

		SET @TotalConcepts = @@ROWCOUNT

		------------------------------------------------------------------------------------------------------------------------------
		-- ForEach concept in concepts
		------------------------------------------------------------------------------------------------------------------------------
		WHILE @CurrentConcept <= @TotalConcepts AND @CurrentDateTime < @TimeLimit AND @CurrentDateTime < @TimeLimitPerRootConcept

		BEGIN 

			SELECT @From = C.SqlSetFrom
				 , @Where = C.SqlSetWhere
				 , @Date = C.SqlFieldDate
				 , @isEncounterBased = C.isEncounterBased
				 , @CurrentConceptId = Id
			FROM #Concepts C
			WHERE RowNumber = @CurrentConcept

			BEGIN TRY 
			
				-- Calculate patient counts for this concept
				EXECUTE app.sp_CalculateConceptPatientCount
					@PersonIdField,
					@TargetDatabaseName,
					@From,
					@Where,
					@Date,
					@isEncounterBased,
					@CurrentRootId,
					@CurrentConceptId

			END TRY BEGIN CATCH END CATCH

			-- Increment the @CurrentConcept parameter
			SET @CurrentConcept = @CurrentConcept + 1
			SET @CurrentDateTime = GETDATE()

		END 
		-- End ForEach concept

		SET @CurrentRoot = @CurrentRoot + 1
		SET @TimeLimitPerRootConcept = DATEADD(MINUTE,@PerRootConceptAllowedRuntimeInMinutes,GETDATE())

	END 
	-- End ForEach root concept


END




-- set version
INSERT INTO [ref].[Version] (Lock, [Version])
SELECT 'X', N'3.2.0';