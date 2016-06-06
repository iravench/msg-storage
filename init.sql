DROP PROCEDURE IF EXISTS allocSession;
DROP TABLE IF EXISTS session;

CREATE TABLE session (
  id MEDIUMINT NOT NULL AUTO_INCREMENT,
  user_id VARCHAR(30) NOT NULL,
  device_id VARCHAR(50) NOT NULL,
  policy VARCHAR(50),
  PRIMARY KEY (id),
  UNIQUE INDEX (user_id, device_id));

delimiter //

CREATE PROCEDURE allocSession
(
  IN i_user_id VARCHAR(30),
  IN i_device_id VARCHAR(50),
  IN i_policy VARCHAR(50)
)
BEGIN
  DECLARE o_id MEDIUMINT;

  SELECT id INTO o_id FROM session WHERE user_id=i_user_id AND device_id=i_device_id;

  IF o_id IS NULL THEN
    INSERT IGNORE INTO session (user_id, device_id, policy) VALUES (i_user_id, i_device_id, i_policy);
    IF LAST_INSERT_ID() > 0 THEN
      SET o_id = LAST_INSERT_ID();
    ELSE
      SELECT id INTO o_id FROM session WHERE user_id=i_user_id AND device_id=i_device_id;
    END IF;
  END IF;

  SELECT o_id;
END//

delimiter ;
