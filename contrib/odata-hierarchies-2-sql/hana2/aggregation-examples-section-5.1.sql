-- Example #1:
-- GET ~/SalesOrganizations?$apply=
--     groupby((rollup(SalesOrgHierarchy)),
--             aggregate($count as OrgCnt)/compute(OrgCnt sub 1 as SubOrgCnt))      
--   &$select=ID,Name,SubOrgCnt
--   &$expand=Superordinate($select=ID)

with _trafo_1 as (
  --     groupby((rollup(SalesOrgHierarchy)),
  --             aggregate($count as OrgCnt)/compute(OrgCnt sub 1 as SubOrgCnt))      
  select node_id as ID, parent_id as Superordinate, Name, OrgCnt
    from hierarchy_descendants_aggregate (
           source hierarchy (
                    source (select ID as node_id,
                                   Superordinate as parent_id,
                                   Name,
                                   row_number() over (order by ID) as SiblingNum,
                                   1 as One
                              from #SalesOrganization )
   
                    sibling order by SiblingNum
                    )
           measures (
             sum (One) as OrgCnt
             )
           )
  )
-- final result with compute(...), $select and $expand
select _trafo_1.ID, _trafo_1.Name, OrgCnt - 1, so2.ID as "Superordinate-ID" 
  from _trafo_1
       inner join #SalesOrganization so1 on _trafo_1.ID = so1.ID
       left join #SalesOrganization so2 on so1.Superordinate = so2.ID
;


-- example #2:
-- GET ~/SalesOrganizations?$apply=
--     /groupby((rollup(SalesOrgHierarchy)),
--              aggregate(Sales/Amount with sum as TotalAmount))
--     /ancestors(SalesOrgHierarchy,filter(contains(Name,'East')),keep start)


with 
  _trafo_1 as (
  --     groupby((rollup(SalesOrgHierarchy)),
  --             aggregate($count as OrgCnt)/compute(OrgCnt sub 1 as SubOrgCnt))      
    select -- return hierarchy structure for further processing
      -- all basic attributes calculated from the hierarchy generator
      node_id, parent_id,
      hierarchy_rank,hierarchy_tree_size,hierarchy_parent_rank,hierarchy_root_rank,
      hierarchy_level,hierarchy_is_cycle,hierarchy_is_orphan,
      -- further model-specific attrbutes
      Name, TotalAmount
      from hierarchy_descendants_aggregate (
             source hierarchy (
                      source (select ID as node_id,
                                     Superordinate as parent_id,
                                     Name,
                                     row_number() over (order by ID) as SiblingNum
                                from #SalesOrganization )
   
                      sibling order by SiblingNum
                      )
             join #Sales on node_id = #Sales.Salesorganization
             measures (
               sum (#Sales.Amount) as TotalAmount
               )
             )
    ),
  _trafo_2 as ( -- /ancestors(SalesOrgHierarchy,filter(contains(Name,'East')),keep start)
    select distinct node_id as ID, parent_id as Superordinate, Name, TotalAmount
      from hierarchy_ancestors (
        source _trafo_1
        start where instr(Name,'East') <> 0
        )
    )
select ID, Superordinate, TotalAmount from _trafo_2
;
