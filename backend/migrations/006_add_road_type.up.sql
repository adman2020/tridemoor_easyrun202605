-- 006_add_road_type.up.sql
-- 给路线表加路面类型字段，支持 AI 分析结合路面环境

ALTER TABLE routes ADD COLUMN road_type TINYINT NOT NULL DEFAULT 0 COMMENT '路面类型：0=通用 1=大马路 2=绿道 3=坡道 4=跑道/操场 5=河边/湖边 6=土路/越野' AFTER difficulty;
