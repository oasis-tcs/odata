-- GET ~/SalesOrganizations?$apply=
--    descendants(SalesOrgHierarchy,filter(Name eq 'US'),keep start)

select distinct node_id as ID, parent_id as Superordinate, Name
from hierarchy_descendants (
       source hierarchy (
                source (select ID as node_id,
                               Superordinate as parent_id,
                               Name,
                               row_number() over (order by ID) as SiblingNum
                          from #SalesOrganization )
  
                sibling order by SiblingNum
                )
       start where Name = 'US'
       )
 ;

-- variation: no KEEP START, i.e.
-- GET ~/SalesOrganizations?$apply=
--    descendants(SalesOrgHierarchy,filter(Name eq 'US'))

select distinct node_id as ID, parent_id as Superordinate, Name
from hierarchy_descendants (
       source hierarchy (
                source (select ID as node_id,
                               Superordinate as parent_id,
                               Name,
                               row_number() over (order by ID) as SiblingNum
                          from #SalesOrganization )
  
                sibling order by SiblingNum
                )
       start where Name = 'US'
       distance from 1
       )
 ;
