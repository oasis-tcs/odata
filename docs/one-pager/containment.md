# Containment

Containment roughly corresponds to "Composition" in UML:

- the "contained" (child) entities have an existential dependency on the "container" (parent) entity
- the key of contained entities is only unique within the container entity
- contained entities can only be reached via the container entity, there is no direct or "shortened" URL for them
- different parents can have children with the same key, these children are different entities because the parent differs
- a contained entity can only have one parent
- a contained entity cannot change its parent, it can only be deleted, and a different entity with a different parent can be created

Containment is a feature of a navigation property only, the same entity type can be used in containment navigation properties, non-containment navigation properties, or entity sets. The "effective key" of a contained entity depends on the context: it is the key of the parent entity plus the (relative) key of the child entity.

Example:

- Orders (identified by a sequence number) have 
- Items (identified by a sequence number within the Order)

These are different entities

~~~url
/Orders/9/items/1
/Orders/9/items/2
/Orders/10/items/2
~~~
