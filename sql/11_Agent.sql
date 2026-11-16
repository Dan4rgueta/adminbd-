-- Tres SQL Server Agent Jobs: FULL 02:00; DIFF 08/14/20; LOG cada 15 min.
USE msdb;
GO
IF NOT EXISTS(SELECT 1 FROM dbo.sysjobs WHERE name=N'GimnasioDB - Full diario')
BEGIN
 EXEC dbo.sp_add_job @job_name=N'GimnasioDB - Full diario',@enabled=1,
 @description=N'Respaldo FULL diario a las 02:00 del servidor.';
 EXEC dbo.sp_add_jobstep @job_name=N'GimnasioDB - Full diario',@step_name=N'FULL',
 @subsystem=N'TSQL',@database_name=N'GimnasioDB',
 @command=N'EXEC mantenimiento.usp_RealizarBackup @Tipo=N''FULL'';',
 @on_success_action=1,@on_fail_action=2;
 EXEC dbo.sp_add_jobserver @job_name=N'GimnasioDB - Full diario';
END;
IF NOT EXISTS(SELECT 1 FROM dbo.sysschedules WHERE name=N'GimnasioDB - Agenda Full 02')
 EXEC dbo.sp_add_schedule @schedule_name=N'GimnasioDB - Agenda Full 02',
 @freq_type=4,@freq_interval=1,@active_start_time=020000;
IF NOT EXISTS (SELECT 1 FROM dbo.sysjobschedules js
 JOIN dbo.sysjobs j ON j.job_id=js.job_id JOIN dbo.sysschedules s ON s.schedule_id=js.schedule_id
 WHERE j.name=N'GimnasioDB - Full diario' AND s.name=N'GimnasioDB - Agenda Full 02')
 EXEC dbo.sp_attach_schedule @job_name=N'GimnasioDB - Full diario',@schedule_name=N'GimnasioDB - Agenda Full 02';
GO
IF NOT EXISTS(SELECT 1 FROM dbo.sysjobs WHERE name=N'GimnasioDB - Diferencial 6h')
BEGIN
 EXEC dbo.sp_add_job @job_name=N'GimnasioDB - Diferencial 6h',@enabled=1,
 @description=N'Respaldo diferencial a las 08,14,20.';
 EXEC dbo.sp_add_jobstep @job_name=N'GimnasioDB - Diferencial 6h',@step_name=N'DIFF',
 @subsystem=N'TSQL',@database_name=N'GimnasioDB',
 @command=N'EXEC mantenimiento.usp_RealizarBackup @Tipo=N''DIFF'';',
 @on_success_action=1,@on_fail_action=2;
 EXEC dbo.sp_add_jobserver @job_name=N'GimnasioDB - Diferencial 6h';
END;
IF NOT EXISTS(SELECT 1 FROM dbo.sysschedules WHERE name=N'GimnasioDB - Agenda Diff 6h')
 EXEC dbo.sp_add_schedule @schedule_name=N'GimnasioDB - Agenda Diff 6h',
 @freq_type=4,@freq_interval=1,@freq_subday_type=8,@freq_subday_interval=6,
 @active_start_time=080000,@active_end_time=200000;
IF NOT EXISTS (SELECT 1 FROM dbo.sysjobschedules js
 JOIN dbo.sysjobs j ON j.job_id=js.job_id JOIN dbo.sysschedules s ON s.schedule_id=js.schedule_id
 WHERE j.name=N'GimnasioDB - Diferencial 6h' AND s.name=N'GimnasioDB - Agenda Diff 6h')
 EXEC dbo.sp_attach_schedule @job_name=N'GimnasioDB - Diferencial 6h',@schedule_name=N'GimnasioDB - Agenda Diff 6h';
GO
IF NOT EXISTS(SELECT 1 FROM dbo.sysjobs WHERE name=N'GimnasioDB - Log 15m')
BEGIN
 EXEC dbo.sp_add_job @job_name=N'GimnasioDB - Log 15m',@enabled=1,
 @description=N'Respaldo del log de transacciones cada 15 minutos.';
 EXEC dbo.sp_add_jobstep @job_name=N'GimnasioDB - Log 15m',@step_name=N'LOG',
 @subsystem=N'TSQL',@database_name=N'GimnasioDB',
 @command=N'EXEC mantenimiento.usp_RealizarBackup @Tipo=N''LOG'';',
 @on_success_action=1,@on_fail_action=2;
 EXEC dbo.sp_add_jobserver @job_name=N'GimnasioDB - Log 15m';
END;
IF NOT EXISTS(SELECT 1 FROM dbo.sysschedules WHERE name=N'GimnasioDB - Agenda Log 15m')
 EXEC dbo.sp_add_schedule @schedule_name=N'GimnasioDB - Agenda Log 15m',
 @freq_type=4,@freq_interval=1,@freq_subday_type=4,@freq_subday_interval=15,
 @active_start_time=000000,@active_end_time=235959;
IF NOT EXISTS (SELECT 1 FROM dbo.sysjobschedules js
 JOIN dbo.sysjobs j ON j.job_id=js.job_id JOIN dbo.sysschedules s ON s.schedule_id=js.schedule_id
 WHERE j.name=N'GimnasioDB - Log 15m' AND s.name=N'GimnasioDB - Agenda Log 15m')
 EXEC dbo.sp_attach_schedule @job_name=N'GimnasioDB - Log 15m',@schedule_name=N'GimnasioDB - Agenda Log 15m';
GO
SELECT j.name AS Job,j.enabled AS Habilitado,s.name AS Agenda,s.freq_type,
 s.freq_subday_type,s.freq_subday_interval,s.active_start_time
FROM dbo.sysjobs j
LEFT JOIN dbo.sysjobschedules js ON js.job_id=j.job_id
LEFT JOIN dbo.sysschedules s ON s.schedule_id=js.schedule_id
WHERE j.name LIKE N'GimnasioDB - %'
ORDER BY Job;
GO
