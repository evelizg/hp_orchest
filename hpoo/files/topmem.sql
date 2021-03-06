SELECT TOP 10
--'High Duration' as Type,
COALESCE(DB_NAME(qt.dbid), DB_NAME(CAST(pa.value as int)), 'Resource') AS 'DBNAME',
--databases.name,
serverproperty('machinename')                                        as 'Server_Name',  
CONVERT(VARCHAR,qs.creation_time) 'creation_time',                                          
--isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name',
SUBSTRING(qt.text,qs.statement_start_offset/2, 
                  (case when qs.statement_end_offset = -1 
                  then len(convert(nvarchar(max), qt.text)) * 2 
                  else qs.statement_end_offset end -qs.statement_start_offset)/2) 
            as query_text,
--		  qt.text,
			--qp.query_plan,
        qs.execution_count as [Execution_Count],
 qs.total_worker_time/1000 as [Total_CPU_Time],
  ((qs.total_worker_time/1000)/60000) as [Total_CPU_Time_Min],
 (qs.total_worker_time/1000)/qs.execution_count as [Avg_CPU_Time],
 qs.total_elapsed_time/1000 as [Total_Duration],
 (qs.total_elapsed_time/1000)/qs.execution_count as [Avg_Duration],
 qs.total_physical_reads as [Total_Physical_Reads],
 qs.total_physical_reads/qs.execution_count as [Avg_Physical_Reads],
  qs.total_logical_reads as [Total_Logical_Reads],
 qs.total_logical_reads/qs.execution_count as [Avg_Logical_Reads]           				          
 FROM sys.dm_exec_query_stats qs
 cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
 outer apply sys.dm_exec_query_plan (qs.plan_handle) qp
 outer APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa 
 --INNER JOIN sys.databases ON qt.dbid = databases.database_id
 where attribute = 'dbid'   
  ---and COALESCE(DB_NAME(qt.dbid), DB_NAME(CAST(pa.value as int)), 'Resource') AS DBNAME
 ---and DB_NAME(CAST(pa.value as int))='CrecimientoBD'--- not in ('msdb','ReportServer','master')
 and DB_NAME(CAST(pa.value as int)) not in ('msdb','ReportServer','master','tempdb')
 ORDER BY [Total_CPU_Time_Min] DESC