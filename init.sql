drop table if exists session, fm_registration;

CREATE TABLE session (
  id MEDIUMINT NOT NULL AUTO_INCREMENT,
  user_id VARCHAR(30) NOT NULL,
  device_id VARCHAR(50) NOT NULL,
  policy VARCHAR(50),
  PRIMARY KEY (id));

CREATE TABLE fm_registration (
  id VARCHAR(10) NOT NULL,
  ip VARCHAR(30) NOT NULL,
  port VARCHAR(10) NOT NULL,
  PRIMARY KEY (id));
