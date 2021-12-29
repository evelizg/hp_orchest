SET NOCOUNT ON

CREATE TABLE #RegResultados
   (
   ResultValue NVARCHAR(4)
   )

CREATE TABLE #ServiceStatus  
   ( 
   RowID INT IDENTITY(1,1)
   ,ServerName NVARCHAR(128) 
   ,ServiceName NVARCHAR(128)
   ,ServiceStatus VARCHAR(128)
   ,StatusDateTime DATETIME DEFAULT (GETDATE())
   ,PhysicalSrverName NVARCHAR(128)
   )

DECLARE 
    @ChkInstanceName NVARCHAR(128)   /*Stores SQL Instance Name*/
   ,@ChkSrvName NVARCHAR(128)        /*Stores Server Name*/
   ,@TrueSrvName NVARCHAR(128)       /*Stores where code name needed */
   ,@SQLSrv NVARCHAR(128)            /*Stores server name*/
   ,@PhysicalSrvName NVARCHAR(128)   /*Stores physical name*/
   ,@DTS NVARCHAR(128)               /*Store SSIS Service Name */
   ,@FTS NVARCHAR(128)               /*Stores Full Text Search Service name*/
   ,@RS NVARCHAR(128)                /*Stores Reporting Service name*/
   ,@SQLAgent NVARCHAR(128)          /*Stores SQL Agent Service name*/
   ,@OLAP NVARCHAR(128)              /*Stores Analysis Service name*/ 
   ,@REGKEY NVARCHAR(128)            /*Stores Registry Key information*/


SET @PhysicalSrvName = CAST(SERVERPROPERTY('MachineName') AS VARCHAR(128)) 
SET @ChkSrvName = CAST(SERVERPROPERTY('INSTANCENAME') AS VARCHAR(128)) 
SET @ChkInstanceName = @@serverName

IF @ChkSrvName IS NULL        /*Detect default or named instance*/
BEGIN 
   SET @TrueSrvName = 'MSSQLSERVER'
   SELECT @OLAP = 'MSSQLServerOLAPService'  /*Setting up proper service name*/
   SELECT @FTS = 'MSFTESQL' 
   SELECT @RS = 'ReportServer' 
   SELECT @SQLAgent = 'SQLSERVERAGENT'
   SELECT @SQLSrv = 'MSSQLSERVER'
END 
ELSE
BEGIN
   SET @TrueSrvName =  CAST(SERVERPROPERTY('INSTANCENAME') AS VARCHAR(128)) 
   SET @SQLSrv = '$'+@ChkSrvName
   SELECT @OLAP = 'MSOLAP' + @SQLSrv /*Setting up proper service name*/
   SELECT @FTS = 'MSFTESQL' + @SQLSrv 
   SELECT @RS = 'ReportServer' + @SQLSrv
   SELECT @SQLAgent = 'SQLAgent' + @SQLSrv
   SELECT @SQLSrv = 'MSSQL' + @SQLSrv
END


/* ---------------------------------- SQL Server Service Section ----------------------------------------------*/

SET @REGKEY = 'System\CurrentControlSet\Services\'+@SQLSrv

INSERT #RegResultados ( ResultValue ) EXEC MASTER.sys.xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key= @REGKEY

IF (SELECT ResultValue FROM #RegResultados) = 1 
BEGIN
   INSERT #ServiceStatus (ServiceStatus)  /*Detecting staus of SQL Sever service*/
   EXEC xp_servicecontrol N'QUERYSTATE',@SQLSrv
   UPDATE #ServiceStatus SET ServiceName = 'MS SQL Server Service' WHERE RowID = @@identity
   UPDATE #ServiceStatus SET ServerName = @TrueSrvName WHERE RowID = @@identity
   UPDATE #ServiceStatus SET PhysicalSrverName = @PhysicalSrvName WHERE RowID = @@identity
   TRUNCATE TABLE #RegResultados
END
ELSE 
BEGIN
   INSERT INTO #ServiceStatus (ServiceStatus) VALUES ('NOT INSTALLED')
   UPDATE #ServiceStatus SET ServiceName = 'MS SQL Server Service' WHERE RowID = @@identity
   UPDATE #ServiceStatus SET ServerName = @TrueSrvName WHERE RowID = @@identity
   UPDATE #ServiceStatus SET PhysicalSrverName = @PhysicalSrvName WHERE RowID = @@identity
   TRUNCATE TABLE #RegResultados
END

/* ---------------------------------- SQL Server Agent Service Section -----------------------------------------*/

SET @REGKEY = 'System\CurrentControlSet\Services\'+@SQLAgent

INSERT #RegResultados ( ResultValue ) EXEC MASTER.sys.xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key= @REGKEY

IF (SELECT ResultValue FROM #RegResultados) = 1 
BEGIN
   INSERT #ServiceStatus (ServiceStatus)  /*Detecting staus of SQL Agent service*/
   EXEC xp_servicecontrol N'QUERYSTATE',@SQLAgent
   UPDATE #ServiceStatus SET ServiceName = 'SQL Server Agent Service' WHERE RowID = @@identity
   UPDATE #ServiceStatus  SET ServerName = @TrueSrvName WHERE RowID = @@identity
   UPDATE #ServiceStatus SET PhysicalSrverName = @PhysicalSrvName WHERE RowID = @@identity
   TRUNCATE TABLE #RegResultados
END
ELSE 
BEGIN
   INSERT INTO #ServiceStatus (ServiceStatus) VALUES ('NOT INSTALLED')
   UPDATE #ServiceStatus SET ServiceName = 'SQL Server Agent Service' WHERE RowID = @@identity
   UPDATE #ServiceStatus SET ServerName = @TrueSrvName WHERE RowID = @@identity 
   UPDATE #ServiceStatus SET PhysicalSrverName = @PhysicalSrvName WHERE RowID = @@identity
   TRUNCATE TABLE #RegResultados
END


/* -------------------------------------------------------------------------------------------------------------*/

SELECT  ServiceName AS 'ServiceName'
   ,ServiceStatus AS 'ServiceStatus'
   ,StatusDateTime AS 'StatusDateTime'
   ,ServerName 
   ,PhysicalSrverName
FROM #ServiceStatus
--FOR XML PATH('qs'),TYPE


/*Perform cleanup*/

DROP TABLE #ServiceStatus    
DROP TABLE #RegResultados