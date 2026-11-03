-- Add migration script here

ALTER TABLE dns_record DROP CONSTRAINT dns_record_zone_id_name_key;
ALTER TABLE dns_record ADD CONSTRAINT dns_record_zone_id_name_type UNIQUE (zone_id, name, type);
