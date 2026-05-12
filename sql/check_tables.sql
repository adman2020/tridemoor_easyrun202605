SELECT 'post_reviews' as table_name, COUNT(*) as cnt FROM post_reviews
UNION ALL SELECT 'admin_roles', COUNT(*) FROM admin_roles
UNION ALL SELECT 'duplicate_groups', COUNT(*) FROM duplicate_groups
UNION ALL SELECT 'cleanup_logs', COUNT(*) FROM cleanup_logs
UNION ALL SELECT 'ai_api_keys', COUNT(*) FROM ai_api_keys
UNION ALL SELECT 'ai_call_logs', COUNT(*) FROM ai_call_logs
UNION ALL SELECT 'device_types', COUNT(*) FROM device_types
UNION ALL SELECT 'device_bind_stats', COUNT(*) FROM device_bind_stats
UNION ALL SELECT 'backup_config', COUNT(*) FROM backup_config
UNION ALL SELECT 'backup_records', COUNT(*) FROM backup_records;
