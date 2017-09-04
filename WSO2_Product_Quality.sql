-- phpMyAdmin SQL Dump
-- version 4.5.4.1deb2ubuntu2
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Aug 15, 2017 at 10:43 AM
-- Server version: 5.7.19-0ubuntu0.16.04.1
-- PHP Version: 7.0.21-1~ubuntu16.04.1+deb.sury.org+1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `WSO2_Product_Quality`
--

-- --------------------------------------------------------

--
-- Table structure for table `pqd_component_repo`
--
CREATE database WSO2_Product_Quality;
use WSO2_Product_Quality;

CREATE TABLE `pqd_component_repo` (
  `pqd_product_id` varchar(200) NOT NULL,
  `pqd_component_name` varchar(200) NOT NULL,
  `pqd_component_id` varchar(200) NOT NULL,
  `pqd_github_repo_name` varchar(200) NOT NULL,
  `pqd_jira_project_name` varchar(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `pqd_component_repo`
--

INSERT INTO `pqd_component_repo` (`pqd_product_id`, `pqd_component_name`, `pqd_component_id`, `pqd_github_repo_name`, `pqd_jira_project_name`) VALUES
('apim', 'carbon-apimgt', 'carbon-apimgt', 'carbon-apimgt', 'ZZZ-carbon-apimgt'),
('apim', 'product-apim', 'product-apim', 'product-apim', 'WSO2 API Manager'),
('iam', 'product-iam', 'product-iam', 'product-is', 'product-is');

-- --------------------------------------------------------

--
-- Table structure for table `pqd_product`
--

CREATE TABLE `pqd_product` (
  `pqd_product_name` varchar(200) NOT NULL,
  `pqd_product_id` varchar(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `pqd_product`
--

INSERT INTO `pqd_product` (`pqd_product_name`, `pqd_product_id`) VALUES
('API MANAGEMENT', 'apim'),
('Identity and Access Management', 'iam');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `pqd_component_repo`
--
ALTER TABLE `pqd_component_repo`
  ADD UNIQUE KEY `pqd_component_id` (`pqd_component_id`);

--
-- Indexes for table `pqd_product`
--
ALTER TABLE `pqd_product`
  ADD UNIQUE KEY `pqd_product_id` (`pqd_product_id`);

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
