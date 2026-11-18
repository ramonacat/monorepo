ALTER TABLE host 
        ADD COLUMN main_ip INET,
        ADD COLUMN region TEXT NOT NULL DEFAULT 'none',
        ADD COLUMN zone TEXT NOT NULL DEFAULT 'az1';
