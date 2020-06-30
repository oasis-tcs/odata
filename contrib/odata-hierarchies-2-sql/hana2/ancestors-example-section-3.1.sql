-- GET ~/SalesOrganizations?$apply=
--    ancestors(SalesOrgHierarchy,
--              filter(contains(Name,'East') or contains(Name,'Central'))

select distinct node_id as ID, parent_id as Superordinate, Name
from hierarchy_ancestors (
       source hierarchy (
                source (select ID as node_id,
                               Superordinate as parent_id,
                               Name,
                               row_number() over (order by ID) as SiblingNum
                          from #SalesOrganization )
  
                sibling order by SiblingNum
                )
       start where instr(Name,'East')<> 0 or instr(Name,'Central') <> 0 
       distance to -1
       )
 ;

  
-- variation: KEEP START, i.e.
-- GET ~/SalesOrganizations?$apply=
--    ancestors(SalesOrgHierarchy,
--              filter(contains(Name,'East') or contains(Name,'Central'),keep start)

select distinct node_id as ID, parent_id as Superordinate, Name
from hierarchy_ancestors (
       source hierarchy (
                source (select ID as node_id,
                               Superordinate as parent_id,
                               Name,
                               row_number() over (order by ID) as SiblingNum
                          from #SalesOrganization )
  
                sibling order by SiblingNum
                )
       start where instr(Name,'East')<> 0 or instr(Name,'Central') <> 0 
       )
 ;
