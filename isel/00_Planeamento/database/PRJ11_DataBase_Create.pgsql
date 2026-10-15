-- Autores:
-- Martim Pinheiro Alves n46286
-- Pedro Jorge n47498
-- Models are created from Django

DROP TABLE Slot;
DROP TABLE Drawer;
DROP TABLE CrashCart;
DROP TABLE Institution;

-- Create Institution table
CREATE TABLE Institution (
    id_i SERIAL PRIMARY KEY,
	name VARCHAR(100) UNIQUE NOT NULL,
	description TEXT
);

-- Create CrashCart table
CREATE TABLE CrashCart (
	id_i INTEGER NOT NULL,
	id_c SERIAL,
	name VARCHAR(20) NOT NULL,
	qr_code_str VARCHAR(20) UNIQUE NOT NULL,
	qr_code_img BYTEA UNIQUE,
	PRIMARY KEY (id_i, id_c),
	CONSTRAINT fk_institution FOREIGN KEY (id_i) REFERENCES Institution (id_i),
    CONSTRAINT unique_cc_name UNIQUE (id_i, name)
);

-- Create Drawer table
CREATE TABLE Drawer (
	id_i INTEGER NOT NULL,
	id_c INTEGER NOT NULL,
	id_d SERIAL,
	name VARCHAR(20) NOT NULL,
	n_lins INTEGER CHECK (n_lins >= 1),
	n_cols INTEGER CHECK (n_cols >= 1),
	qr_code_str VARCHAR(20) UNIQUE NOT NULL,
	qr_code_img BYTEA UNIQUE,
	PRIMARY KEY (id_i, id_c, id_d),
	CONSTRAINT fk_crashcart FOREIGN KEY (id_i, id_c) REFERENCES CrashCart (id_i, id_c)
	CONSTRAINT unique_d_name UNIQUE (id_i, id_c, name)
);

-- Create Slot table
CREATE TABLE Slot (
	id_i INTEGER NOT NULL,
	id_c INTEGER NOT NULL,
	id_d INTEGER NOT NULL,
	id_s SERIAL,
	name VARCHAR(20) NOT NULL,
	s_adj_hor INTEGER CHECK (s_adj_hor >= 1) NOT NULL,
	s_adj_ver INTEGER CHECK (s_adj_ver >= 1) NOT NULL,
	name_prod VARCHAR(50) NOT NULL,
	vol_weight VARCHAR(50) NOT NULL,
	application VARCHAR(100) NULL,
	max_quant INTEGER CHECK (max_quant >= 1) NOT NULL,
	valid_date DATE NULL,
	qr_code_str VARCHAR(20) UNIQUE NOT NULL,
	qr_code_img BYTEA UNIQUE,
	PRIMARY KEY (id_i, id_c, id_d, id_s),
	CONSTRAINT fk_drawer FOREIGN KEY (id_i, id_c, id_d) REFERENCES Drawer (id_i, id_c, id_d),
    CONSTRAINT unique_sp_name UNIQUE (id_i, id_c, id_d, name)
);