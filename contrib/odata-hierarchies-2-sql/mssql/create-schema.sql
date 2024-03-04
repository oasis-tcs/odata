USE [SalesDemoDB];

CREATE TABLE Sales
(
  ID                varchar(8) NOT NULL,
  Customer          varchar(10) NOT NULL,
  Time              date NOT NULL,
  Product           varchar(10) NOT NULL,
  SalesOrganization varchar(20) NOT NULL,
  Currency          varchar(10) NOT NULL,
  Amount            decimal(10,2)
);

INSERT INTO Sales VALUES ('1', 'C1', '2012-01-03', 'P3', 'US West', 'USD', '1');
INSERT INTO Sales VALUES ('2', 'C1', '2012-04-10', 'P1', 'US West', 'USD', '2');
INSERT INTO Sales VALUES ('3', 'C1', '2012-08-07', 'P2', 'US West', 'USD', '4');
INSERT INTO Sales VALUES ('4', 'C2', '2012-11-03', 'P2', 'US East', 'USD', '8');
INSERT INTO Sales VALUES ('5', 'C2', '2012-11-09', 'P3', 'US East', 'USD', '4');
INSERT INTO Sales VALUES ('6', 'C3', '2012-04-01', 'P1', 'EMEA Central', 'EUR', '2');
INSERT INTO Sales VALUES ('7', 'C3', '2012-08-06', 'P3', 'EMEA Central', 'EUR', '1');
INSERT INTO Sales VALUES ('8', 'C3', '2012-11-22', 'P3', 'EMEA Central', 'EUR', '2');

CREATE TABLE SalesOrganization
(
  ID varchar(20) NOT NULL,
  Superordinate varchar(20),
  Name varchar(60)
);
  
INSERT INTO SalesOrganization VALUES ('US East', 'US', 'US East');
INSERT INTO SalesOrganization VALUES ('Sales', null, 'Corporate Sales');
INSERT INTO SalesOrganization VALUES ('US', 'Sales', 'US');
INSERT INTO SalesOrganization VALUES ('EMEA', 'Sales', 'EMEA');
INSERT INTO SalesOrganization VALUES ('US West', 'US', 'US West');
INSERT INTO SalesOrganization VALUES ('EMEA Central', 'EMEA', 'EMEA Central');
