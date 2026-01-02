.read "create-schema.sql"

-- logic for a depth first search traversal of a hierarchy
with recursive
  -- traversal needs a stable sibling order; can be rowid if selecting from hierarchy table, or row_number() if preceding transformation
  salesorg_w_sibling(ID,Superordinate,Name,SiblingIdx) as (select *,rowid from SalesOrganization),
  parent_of(node,parent_node) as (select id, Superordinate from salesorg_w_sibling),
  dfs_traversal_of(node, path) as (
    select id, '0001' from salesorg_w_sibling -- start with root node
     where Superordinate is null 
     union
    select parent_of.node,
           path || '.' || substr('000' || cast(SiblingIdx as string),-4) -- build lexicographical sequence for each node
      from dfs_traversal_of
           inner join parent_of on parent_of.parent_node = dfs_traversal_of.node
           inner join salesorg_w_sibling on parent_of.node = salesorg_w_sibling.id
    )
select SalesOrganization.*,dfs_traversal_of.path from SalesOrganization inner join dfs_traversal_of on id = node
 order by dfs_traversal_of.path asc
;


-- applied to example from spec:
-- GET ~/SalesOrganizations?$apply=
--     descendants(SalesOrgHierarchy,filter(Name eq 'US'),keep start)
--     /ancestors(SalesOrgHierarchy,filter(contains(Name,'East')),keep start)
--     /traverse(SalesOrgHierarchy,preorder)

-- Develop the different transformations in two steps

-- step #1: $apply=descendants(...)/ancestors(...)

with recursive
  parent_of(node,parent_node) as (select id, Superordinate from SalesOrganization), -- generic parent relation from hier def
  descendants_of(node) as (
    select id from SalesOrganization    -- set of start nodes from filter expression passed to descendants()
     where name = 'US' 
     union
    select parent_of.node               -- generic descendants recursion derived from hier def
      from descendants_of inner join parent_of on parent_of.parent_node = descendants_of.node
    ),
  trafo_1_result(ID,SuperOrdinate,Name) as ( -- result of descendants(...)
    select SalesOrganization.* from SalesOrganization inner join descendants_of on id = node
    ),
-- CTEs for ancestors
  ancestors_of(node) as (
    select ID from trafo_1_result       -- set of start nodes from filter expression and considering "keep start"
     where instr(name,'East')<> 0 
     union
    select parent_node from ancestors_of inner join parent_of on parent_of.node = ancestors_of.node
    )
select trafo_1_result.* from trafo_1_result inner join ancestors_of on id = node
;


-- step #2: $apply=descendants(...)/ancestors(...)//traverse(SalesOrgHierarchy,preorder)
with recursive
-- CTEs for descendants
  parent_of(node,parent_node) as (select id, Superordinate from SalesOrganization), -- generic parent relation from hier def
  descendants_of(node) as (
    select id from SalesOrganization    -- set of start nodes from filter expression passed to descendants()
     where name = 'US' 
     union
    select parent_of.node               -- generic descendants recursion derived from hier def 
      from descendants_of inner join parent_of on parent_of.parent_node = descendants_of.node
    ),
  trafo_1_result(ID,SuperOrdinate,Name,SiblingIndex) as ( -- result of descendants(...), use row_id as sibling order
    select SalesOrganization.*,SalesOrganization.rowid from SalesOrganization, descendants_of where id = node
    ),
-- CTEs for ancestors
  ancestors_of(node) as (
    select ID from trafo_1_result       -- set of start nodes from filter expression and considering "keep start"
     where instr(name,'East')<> 0 
     union
    select parent_node from ancestors_of inner join parent_of on parent_of.node = ancestors_of.node
    ),
  trafo_2_result(ID,SuperOrdinate,Name,SiblingIndex) as ( -- result of ancestors(...)
    select trafo_1_result.* from trafo_1_result inner join ancestors_of on id = node
    ),
-- CTEs for traverse
  parent_of2(node,parent_node) as (select id, Superordinate from trafo_2_result),
  dfs_traversal_of(node, path) as (
    select id, '0001' from trafo_2_result 
     where name = 'US' 
     union
    select parent_of2.node,
           path || '.' || substr('000' || cast(SiblingIndex as string),-4) 
      from dfs_traversal_of
           inner join parent_of2 on parent_of2.parent_node = dfs_traversal_of.node
           inner join trafo_2_result on parent_of2.node = trafo_2_result.id
    )
-- select * from salesorg_w_sibling_id
select trafo_2_result.ID,trafo_2_result.SuperOrdinate,trafo_2_result.Name,dfs_traversal_of.path 
  from trafo_2_result inner join dfs_traversal_of on id = node
 order by dfs_traversal_of.path asc    
    
;

