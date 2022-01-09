.read "create-schema.sql"


-- GET ~/SalesOrganizations?$apply=
--    ancestors(SalesOrgHierarchy,
--              filter(contains(Name,'East') or contains(Name,'Central'))


with recursive
  parent_of(node,parent_node) as (select id, Superordinate from SalesOrganization), -- generic parent relation from hier def
  ancestors_of(node) as (
    select parent_node    -- set of (parent) start nodes from filter expression passed to ancestors()
      from SalesOrganization
           inner join parent_of on parent_of.node = id
     where instr(name,'East')<> 0 or instr(name,'Central') <> 0 
     union
    select parent_node 
      from ancestors_of   -- generic ancestors recursion derived from hierarchy definition
           inner join parent_of on parent_of.node = ancestors_of.node
    )
select SalesOrganization.* from SalesOrganization inner join ancestors_of on id = node  -- output result
;
 
-- variation: KEEP START, i.e.
-- GET ~/SalesOrganizations?$apply=
--    ancestors(SalesOrgHierarchy,
--              filter(contains(Name,'East') or contains(Name,'Central'),keep start)

with recursive
  parent_of(node,parent_node) as (select id, Superordinate from SalesOrganization), -- generic parent relation from hier def
  ancestors_of(node) as (
    select ID             -- set of (parent) start nodes from filter expression passed to ancestors()
      from SalesOrganization
     where instr(name,'East')<> 0 or instr(name,'Central') <> 0 
     union
    select parent_node 
      from ancestors_of   -- generic ancestors recursion derived from hierarchy definition
           inner join parent_of on parent_of.node = ancestors_of.node
    )
select SalesOrganization.* from SalesOrganization inner join ancestors_of on id = node  -- output result
;
