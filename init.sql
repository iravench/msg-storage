drop table if exists session;

CREATE TABLE session (
  id MEDIUMINT NOT NULL AUTO_INCREMENT,
  user_id VARCHAR(30) NOT NULL,
  device_id VARCHAR(50) NOT NULL,
  policy VARCHAR(50),
  PRIMARY KEY (id));
