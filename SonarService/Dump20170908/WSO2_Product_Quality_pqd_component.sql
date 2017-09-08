CREATE DATABASE  IF NOT EXISTS `WSO2_Product_Quality` /*!40100 DEFAULT CHARACTER SET latin1 */;
USE `WSO2_Product_Quality`;
-- MySQL dump 10.13  Distrib 5.5.57, for debian-linux-gnu (x86_64)
--
-- Host: 127.0.0.1    Database: WSO2_Product_Quality
-- ------------------------------------------------------
-- Server version	5.5.57-0ubuntu0.14.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `pqd_component`
--

DROP TABLE IF EXISTS `pqd_component`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pqd_component` (
  `pqd_component_id` varchar(200) NOT NULL,
  `pqd_product_name` varchar(200) NOT NULL,
  `pqd_github_repo_name` varchar(200) DEFAULT NULL,
  `pqd_sonar_project_key` varchar(300) DEFAULT NULL,
  `pqd_jira_project_name` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`pqd_component_id`),
  KEY `fk_pqd_component_1_idx` (`pqd_product_name`),
  CONSTRAINT `pqd_product_name` FOREIGN KEY (`pqd_product_name`) REFERENCES `pqd_product` (`pqd_product_name`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pqd_component`
--

LOCK TABLES `pqd_component` WRITE;
/*!40000 ALTER TABLE `pqd_component` DISABLE KEYS */;
INSERT INTO `pqd_component` VALUES ('analytics-apim','Streaming Analytics','org.wso2.analytics.apim:analytics-apim','org.wso2.analytics.apim:analytics-apim',NULL),('analytics-cdmf','Streaming Analytics','org.wso2.carbon.analytics.cdmf:wso2analytics-cdmf-parent','org.wso2.carbon.analytics.cdmf:wso2analytics-cdmf-parent',NULL),('analytics-data-agents','Streaming Analytics','wso2:instrumentation-agent','wso2:instrumentation-agent',NULL),('carbon-analytics__java8','Streaming Analytics','org.wso2.carbon.analytics:carbon-analytics','org.wso2.carbon.analytics:carbon-analytics',NULL),('carbon-apimgt','API Management','org.wso2.carbon.apimgt:carbon-apimgt','org.wso2.carbon.apimgt:carbon-apimgt',NULL),('carbon-apimgt-staged','API Management','org.wso2.carbon.apimgt:carbon-apimgt:Staged','org.wso2.carbon.apimgt:carbon-apimgt:Staged',NULL),('carbon-appmgt','Identity and Access Management','org.wso2.carbon.appmgt:carbon-appmgt','org.wso2.carbon.appmgt:carbon-appmgt',NULL),('carbon-business-process:carbon-business-process__java8','Integration','org.wso2.carbon.business-process:carbon-business-process:carbon-business-process__java8','org.wso2.carbon.business-process:carbon-business-process:carbon-business-process__java8',NULL),('carbon-commons__java8','Platform','org.wso2.carbon.commons:carbon-commons:carbon-commons__java8','org.wso2.carbon.commons:carbon-commons:carbon-commons__java8',NULL),('carbon-dashboards__java8','Streaming Analytics','org.wso2.carbon.dashboards:carbon-dashboards:carbon-dashboards__java8','org.wso2.carbon.dashboards:carbon-dashboards:carbon-dashboards__java8',NULL),('carbon-data__java8','Integration','org.wso2.carbon.data:carbon-data:carbon-data__java8','org.wso2.carbon.data:carbon-data:carbon-data__java8',NULL),('carbon-device-mgt-plugins','IoT','org.wso2.carbon.devicemgt-plugins:carbon-device-mgt-plugins-parent','org.wso2.carbon.devicemgt-plugins:carbon-device-mgt-plugins-parent',NULL),('carbon-identity','Identity and Access Management','org.wso2.carbon.identity:carbon-identity:carbon-identity','org.wso2.carbon.identity:carbon-identity:carbon-identity',NULL),('carbon-identity_test','Identity and Access Management','org.wso2.carbon.identity:carbon-identity:carbon-identity_test','org.wso2.carbon.identity:carbon-identity:carbon-identity_test',NULL),('carbon-mediation','Integration','org.wso2.carbon.mediation:carbon-mediation','org.wso2.carbon.mediation:carbon-mediation',NULL),('carbon-mediation:carbon-mediation','Integration','org.wso2.carbon.mediation:carbon-mediation:carbon-mediation','org.wso2.carbon.mediation:carbon-mediation:carbon-mediation',NULL),('carbon-messaging_java8','Platform','org.wso2.carbon.messaging:business-messaging:carbon-business-messaging__java8','org.wso2.carbon.messaging:business-messaging:carbon-business-messaging__java8',NULL),('carbon-metrics','Other','org.wso2.carbon.metrics:carbon-metrics','org.wso2.carbon.metrics:carbon-metrics',NULL),('carbon-storage-management','Cloud','org.wso2.carbon.storagemgt:carbon-storage-management','org.wso2.carbon.storagemgt:carbon-storage-management',NULL),('identity-application-auth-openid','Identity and Access Management','org.wso2.carbon.identity.outbound.auth.openid:identity-application-auth-openid','org.wso2.carbon.identity.outbound.auth.openid:identity-application-auth-openid',NULL),('identity-inbound-auth-openid','Identity and Access Management','org.wso2.carbon.identity.inbound.auth.openid:identity-inbound-auth-openid','org.wso2.carbon.identity.inbound.auth.openid:identity-inbound-auth-openid',NULL),('identity-outbound-auth-amazon','Platform Extension','org.wso2.carbon.extension.identity.authenticator.outbound.amazon:identity-outbound-auth-amazon','org.wso2.carbon.extension.identity.authenticator.outbound.amazon:identity-outbound-auth-amazon',''),('product-apim','API Management','org.wso2.am:am-parent','org.wso2.am:am-parent','product-apim'),('product-cep','Streaming Analytics','org.wso2.cep:wso2cep-parent','org.wso2.cep:wso2cep-parent','product-cep'),('product-ei','Integration','org.wso2.ei:wso2ei-parent','org.wso2.ei:wso2ei-parent','product-ei'),('product-iot','IoT','org.wso2.iot:wso2iot-parent','org.wso2.iot:wso2iot-parent','product-iot'),('product-is','Identity and Access Management','org.wso2.is:product-is','org.wso2.is:product-is','product-is'),('rampart-project','Identity and Access Management','org.apache.rampart:rampart-project','org.apache.rampart:rampart-project',NULL),('wso2-cassandra','Cloud','org.apache.cassandra:apache-cassandra','org.apache.cassandra:apache-cassandra',NULL);
/*!40000 ALTER TABLE `pqd_component` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-09-08  8:38:39
