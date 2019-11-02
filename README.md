# football-plus-minus

Arrange your data so that you have one row per play. EPA on that play is your response variable and the matrix of 0's for players not on the field, 1 if the player was on offense and -1 if the player was on defense. 

Use the sparse matrix in R and then extract the 3 parts to feed to stan as seen here: 
```
X.model <- sparseMatrix(i = participation.model$play.index, j = participation.model$player.index, x = participation.model$Offense)
  sparse.parts <- extract_sparse_parts(X.model)
```
