CREATE FUNCTION dns_zone__update_serial() RETURNS TRIGGER AS $trig$
    BEGIN
        IF 
            NEW.name != OLD.name 
            OR NEW.refresh != OLD.refresh
            OR NEW.retry != OLD.retry
            OR NEW.expire != OLD.expire
            OR NEW.negative_response_ttl != OLD.negative_response_ttl
            OR NEW.default_ttl != OLD.default_ttl
        THEN
            NEW.serial := OLD.serial + 1;
        END IF;

        RETURN NEW;
    END;
$trig$ LANGUAGE plpgsql;

CREATE TRIGGER dns_zone__update_serial BEFORE UPDATE ON dns_zone FOR EACH ROW EXECUTE FUNCTION dns_zone__update_serial();

CREATE FUNCTION dns_record__update_parent_serial() RETURNS TRIGGER AS $trig$
    BEGIN
        IF OLD IS NULL THEN
            UPDATE dns_zone SET serial=serial+1 WHERE id=NEW.zone_id;
            
            RETURN NEW;
        END IF;

        IF NEW.zone_id != OLD.zone_id THEN 
            UPDATE dns_zone SET serial=serial+1 WHERE id IN (OLD.zone_id, NEW.zone_id);

            RETURN NEW;
        END IF;

        IF 
            NEW.name != OLD.name
            OR NEW.type != OLD.type
            OR NEW.rrdatas != OLD.rrdatas
            OR NEW.ttl != OLD.ttl
        THEN
            UPDATE dns_zone SET serial=serial+1 WHERE id = NEW.zone_id;
        END IF;

        RETURN NEW;
    END;
$trig$ LANGUAGE plpgsql;

CREATE TRIGGER dns_record__update_parent_serial AFTER UPDATE OR INSERT ON dns_record FOR EACH ROW EXECUTE FUNCTION dns_record__update_parent_serial();
