.read "create-schema.sql"

-- GET ~/SalesOrganizations?$apply=
--    descendants(SalesOrgHierarchy,filter(Name eq 'US'),keep start)

with recursive
  parent_of(node,parent_node) as (select id, Superordinate from SalesOrganization), -- generic parent relation from hier def
  descendants_of(node) as (
    select id from SalesOrganization     -- set of start nodes from filter expression passed to descendants()
     where name = 'US' 
     union
    select parent_of.node                -- generic descendants recursion derived from hier def
      from descendants_of inner join parent_of on parent_of.parent_node = descendants_of.node
    )
select SalesOrganization.* from SalesOrganization inner join descendants_of on id = node  -- output result
;


-- variation: no KEEP START, i.e.
-- GET ~/SalesOrganizations?$apply=
--    descendants(SalesOrgHierarchy,filter(Name eq 'US'))

with recursive
  parent_of(node,parent_node) as (select id, Superordinate from SalesOrganization), -- generic parent relation from hier def
  descendants_of(node) as (
    select node              -- set of (children) start nodes from filter expression passed to descendants()
      from SalesOrganization inner join parent_of on parent_of.parent_node = id
     where name = 'US' 
     union
    select parent_of.node    -- generic descendants recursion derived from hier def
      from descendants_of inner join parent_of on parent_of.parent_node = descendants_of.node
    )
select SalesOrganization.* from SalesOrganization, descendants_of where id = node  -- output result
;
