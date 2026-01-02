

-- logic for a depth first search traversal of a hierarchy
select distinct node_id as ID, parent_id as Superordinate, Name, hierarchy_rank
from hierarchy (
       source (select ID as node_id,
                      Superordinate as parent_id,
                      Name,
                      row_number() over (order by ID) as SiblingNum
                 from #SalesOrganization )
  
       sibling order by SiblingNum
       )
order by hierarchy_rank       
 ;


-- applied to example from spec:
-- GET ~/SalesOrganizations?$apply=
--     descendants(SalesOrgHierarchy,filter(Name eq 'US'),keep start)
--     /ancestors(SalesOrgHierarchy,filter(contains(Name,'East')),keep start)
--     /traverse(SalesOrgHierarchy,preorder)

with 
_trafo_1 as ( --     descendants(SalesOrgHierarchy,filter(Name eq 'US'),keep start)
  select distinct -- return hierarchy structure for further processing
    -- all basic attributes calculated from the hierarchy generator
    node_id, parent_id,
    hierarchy_rank,hierarchy_tree_size,hierarchy_parent_rank,hierarchy_root_rank,
    hierarchy_level,hierarchy_is_cycle,hierarchy_is_orphan,
    -- further model-specific attrbutes
    Name, SiblingNum
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
  ),
_trafo_2 as ( --   /ancestors(SalesOrgHierarchy,filter(contains(Name,'East')),keep start)
  select distinct node_id as ID, parent_id as Superordinate, Name, hierarchy_rank
    from hierarchy_ancestors (
           source _trafo_1
           start where instr(Name,'East') <> 0 
           )
  )
-- /traverse(SalesOrgHierarchy,preorder) 
select ID, Superordinate, Name, hierarchy_rank
  from _trafo_2
 order by hierarchy_rank
 ;

