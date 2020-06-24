create table Sales (
  ID varchar(8) not null,
  Customer varchar(10) not null,
  Time date not null,
  Product varchar(10) not null,
  SalesOrganization varchar(20) not null,
  Currency varchar(10) not null,
  Amount decimal(10,2)
  );

insert into Sales values ('1', 'C1', '2012-01-03', 'P3', 'US West', 'USD', '1');
insert into Sales values ('2', 'C1', '2012-04-10', 'P1', 'US West', 'USD', '2');
insert into Sales values ('3', 'C1', '2012-08-07', 'P2', 'US West', 'USD', '4');
insert into Sales values ('4', 'C2', '2012-11-03', 'P2', 'US East', 'USD', '8');
insert into Sales values ('5', 'C2', '2012-11-09', 'P3', 'US East', 'USD', '4');
insert into Sales values ('6', 'C3', '2012-04-01', 'P1', 'EMEA Central', 'EUR', '2');
insert into Sales values ('7', 'C3', '2012-08-06', 'P3', 'EMEA Central', 'EUR', '1');
insert into Sales values ('8', 'C3', '2012-11-22', 'P3', 'EMEA Central', 'EUR', '2');

create table SalesOrganization (
  ID varchar(20) not null,
  Superordinate varchar(20),
  Name varchar(60)
  );
  
insert into SalesOrganization values ('US East', 'US', 'US East');
insert into SalesOrganization values ('Sales', null, 'Corporate Sales');
insert into SalesOrganization values ('US', 'Sales', 'US');
insert into SalesOrganization values ('EMEA', 'Sales', 'EMEA');
insert into SalesOrganization values ('US West', 'US', 'US West');
insert into SalesOrganization values ('EMEA Central', 'EMEA', 'EMEA Central');
