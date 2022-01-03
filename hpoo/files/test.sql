INSERT INTO ServiceStatus(ServiceName, ServiceStatus, StatusDateTime, ServerName, PhysicalSrverName)
SELECT ServiceName, ServiceStatus, StatusDateTime, ServerName, PhysicalSrverName
FROM #ServiceStatus