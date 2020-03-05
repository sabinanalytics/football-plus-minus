# football-plus-minus

Arrange your data so that you have one row per play. EPA on that play is your response variable and the matrix of 0's for players not on the field, 1 if the player was on offense and -1 if the player was on defense. 

Use the sparse matrix in R and then extract the 3 parts to feed to stan as seen here: 
```
X.model <- sparseMatrix(i = participation.model$play.index, j = participation.model$player.index, x = participation.model$Offense)
  sparse.parts <- extract_sparse_parts(X.model)
```

**For both College and NFL data shown:**

These results are "semi-predictive" as in they use the last seasons information as a prior. This is why Joe Burrow didn't rise to No. 1 in 2019, because his prior from 2018 was still holding him back. Eventually these will be replaced with "Box Plus-Minus" priors for each position that only reflect in-season performance so that descriptive and predictive versions will be separate. 


Also for these models shown, runs and passes are in the same model, and run plays have their own mean and variance estimated by the model. This does mean that a player that is a superior passer but is often involved in less-efficient run plays won't get the same credit as if he was in an offense that was more optimal and passed the ball more (see Russell Wilson). 


**NFL:**

*Data from 2008 to 2019*

The data in the NFL folder is for a model that spans two season intervals. The season listed is the second season. Players with more than 100 plays in this span are included. 


**College:**

*Data from 2018 to 2019*

One Stan file is included for a version of the model that uses prior season information and combines runs/passes into one model/
There are also 2 other stan files that contain no prior year information and separate models for runs vs passes. 


There are also 2 rds files that show posterior samples from the stan code for the model at the end of each season with the models separated for runs and passes. 
