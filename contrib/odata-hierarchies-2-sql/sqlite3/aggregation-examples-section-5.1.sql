.read "create-schema.sql"

-- Example #1:
-- GET ~/SalesOrganizations?$apply=
--     groupby((rollup(SalesOrgHierarchy)),
--             aggregate($count as OrgCnt)/compute(OrgCnt sub 1 as SubOrgCnt))      
--   &$select=ID,Name,SubOrgCnt
--   &$expand=Superordinate($select=ID)

with recursive
  ancestor_relation(node,ancestor) as (  -- all node pairs on a common path
    select id, id
      from SalesOrganization
    union all
    select SalesOrganization.id,ancestor_relation.ancestor
      from ancestor_relation inner join SalesOrganization on SalesOrganization.Superordinate = ancestor_relation.node
    ),
  trafo_1_result(node,cnt) as (          -- groupby((rollup(...),aggregate(...)
    select ancestor_relation.ancestor, count(*)
      from ancestor_relation inner join SalesOrganization on ancestor_relation.ancestor = SalesOrganization.id
    group by ancestor_relation.ancestor
    )
select node, so1.name, so2.ID, cnt - 1 -- final result with compute(...), $select and $expand
  from trafo_1_result 
       inner join SalesOrganization so1 on trafo_1_result.node = so1.ID
       left join SalesOrganization so2 on so1.Superordinate = so2.ID
;

-- example #2:
-- GET ~/SalesOrganizations?$apply=
--     /groupby((rollup(SalesOrgHierarchy)),
--              aggregate(Sales/Amount with sum as TotalAmount))
--     /ancestors(SalesOrgHierarchy,filter(contains(Name,'East')),keep start)

-- Develop the different transformations in two steps

-- step #1: /groupby((rollup(...)), aggregate(...))
with recursive
  ancestor_relation(node,ancestor,Amount) as ( -- all node pairs plus fields to be aggregated (Amount in this example)
    select SalesOrganization.id, SalesOrganization.id, Sales.Amount
      from SalesOrganization
           left outer join Sales on SalesOrganization.id = Sales.SalesOrganization
    union all
    select SalesOrganization.id,ancestor_relation.ancestor, Sales.Amount
      from ancestor_relation 
           inner join SalesOrganization on SalesOrganization.Superordinate = ancestor_relation.node
           left outer join Sales on SalesOrganization.id = Sales.SalesOrganization
    )
select ancestor_relation.ancestor, SalesOrganization.Superordinate, sum(ancestor_relation.Amount)
  from ancestor_relation 
       inner join SalesOrganization on ancestor_relation.ancestor = SalesOrganization.id
  group by ancestor_relation.ancestor, SalesOrganization.Superordinate
;

-- step #2: /groupby((rollup(...)), aggregate(...))/ancestors(...)
with recursive
-- CTEs for groupby(..., aggregate(...))
  ancestor_relation(node,ancestor,Amount) as ( -- all node pairs plus fields to be aggregated (Amount in this example)
    select SalesOrganization.id, SalesOrganization.id, Sales.Amount
      from SalesOrganization
           left outer join Sales on SalesOrganization.id = Sales.SalesOrganization
    union all
    select SalesOrganization.id,ancestor_relation.ancestor, Sales.Amount
      from ancestor_relation 
           inner join SalesOrganization on SalesOrganization.Superordinate = ancestor_relation.node
           left outer join Sales on SalesOrganization.id = Sales.SalesOrganization
    ),
  trafo_1_result(ID, Superordinate, Name, aggAmount) as (
    select ancestor_relation.ancestor, SalesOrganization.Superordinate, SalesOrganization.Name, 
           sum(ancestor_relation.Amount)
      from ancestor_relation 
           inner join SalesOrganization on ancestor_relation.ancestor = SalesOrganization.id
     group by ancestor_relation.ancestor, SalesOrganization.Superordinate
    ),
-- CTEs for ancestors(...)
  parent_of(node,parent_node) as (select ID, Superordinate from trafo_1_result), -- generic parent relation from hier def
  ancestors_of(node) as (
    select ID    -- set of (parent) start nodes from filter expression passed to ancestors()
      from trafo_1_result
     where instr(Name,'East')<> 0  
     union
    select parent_node              -- generic ancestors recursion derived from hier def
      from ancestors_of inner join parent_of on parent_of.node = ancestors_of.node
    )
select * from trafo_1_result inner join ancestors_of on id = node  -- output result
;
