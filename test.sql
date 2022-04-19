CREATE SCHEMA IF NOT EXISTS `test` DEFAULT CHARACTER SET utf8 ;

USE `test`;
CREATE TABLE IF NOT EXISTS `test`.`table1` (
  `Id` VARCHAR(36) NOT NULL COMMENT '主键',
  `Name` VARCHAR(128) NOT NULL COMMENT '名称',
  PRIMARY KEY (`Id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COMMENT = '测试表';