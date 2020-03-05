
data {
int<lower=1> N; //number of data points
real y[N]; //response variable, y is a set of integers

int<lower=-1, upper = 1> home[N]; // variable denoting home/away/neutral (-1 for away, 0 for neutral, 1 for home)

int<lower=1> nPlayers; //number of Players
int<lower=1, upper=nPlayers> PlayerID[nPlayers]; //player id

int<lower=1> nPlayType; //number of different play types
int<lower=1, upper=nPlayType> playType[N]; //variable denoting what type of play it was


int<lower=1> nPosition; //number of unique position groups
int<lower=1, upper=nPosition> positions[nPlayers]; //the main position for each player

int<lower=1> nPlayerPlays; //total number of plays by all players (should be about nPlayers*N)


vector [nPlayerPlays] wX; // values of sparse design matrix
int <lower = 1> vX[nPlayerPlays]; // column indicators of sparse matrix
int <lower = 1> uX[N+1]; // row indicators of sparse matrix

matrix<lower =0, upper = 1>[nPlayers, nPosition] posMat;//Matrix of fraction of time each player spends at each position

///prior variables
int<lower=1> nDraftRounds     ; // number of rounds in NFL Draft (+1 for undraftees)

int<lower=0, upper = 1>            drafted[nPlayers]      ; // whether or not a player was drafted in the NFL draft
int<lower=0, upper = 1>            undrafted[nPlayers]    ; // whether or not a player was drafted in the NFL draft
int<lower=0, upper = 1>            earlyEntrant[nPlayers] ;//whether or not the drafter player was an early entrant to the NFL draft
int<lower=0, upper = nDraftRounds> draftRound[nPlayers]   ; // which round a player was drafted in, 8 = undrafted

real<lower=-2>  pickOverall[nPlayers] ;//Overall Pick in NFL Draft (260 means undrafted)
}



transformed data {
}

parameters {
vector[nPlayers] b; //player intercepts
//vector[nPlayType] u; //play types intercepts

real u; // effect for home field on a per play basis 
vector[nPlayType] g; // effects for each play type (can't have intercept or else model may not be identifiable)

vector<lower=0>[nPosition] phi; // multiplicative adjustment to variance of player mean by position (different one for each main position - serves as different shrinkage parameters)

vector[nDraftRounds] alpha;//Prior coefficients for mean player value

vector<lower=0>[nPlayType] s2model; //model variance -- different variance for run v. pass
//real<lower=0> s2model; //model variance
real<lower=0> s2player; //across player variance
real<lower=0> s2playType; //across play type variance

}

transformed parameters {
vector[N] eta;  // linear predictor
// compute linear predictor
eta = csr_matrix_times_vector(N, nPlayers, wX, vX, uX, b);
}


model{

real mu[N]; //temporary regression variable

vector[nPlayers] positionVarCoef; // variance multiplier for each player
vector[nPlayers] playerPriorMean; // prior mean for each player



//Priors

//priors and hyperpriors on players
for(i in 1:nPlayers){
  positionVarCoef[i] = posMat[i,]*phi ; //multiplier for how often a player plays in each position

  b[i]~student_t(8, alpha[draftRound[i]], positionVarCoef[i] * sqrt(s2player));//
}

s2player ~ gamma(0.05 , 0.11); // in a later version I may be able to change 0.03 and 10 to their own parameters


 
//Different variances per position (each player gets 1 dominant position)
phi[1] ~  gamma(27.3, 7.75)    ;//QB 0.1,25
phi[2] ~  gamma(5.1 , 6.2 )    ;//HB (Runnning back and fullback)
phi[3] ~  gamma(6.4 , 5.65)    ;//SWR (inlcuding slot receivers)
phi[4] ~  gamma(6.5 , 4.96)    ;//WR (inlcuding slot receivers)
phi[5] ~  gamma(1.77, 14.4)    ;//TE not quite converged
phi[6] ~  gamma(62.5, 50  )    ;//OT (tackle, guard, and center)
phi[7] ~  gamma(23.8, 22.2)    ;//G (tackle, guard, and center)
phi[8] ~  gamma(26.4, 14.9)    ;//C (tackle, guard, and center)
phi[9] ~  gamma(35.7, 38.1)    ;//DT (defensive nose tackle)
phi[10] ~ gamma(10.5, 10.5)    ;//DE (defensive end )
phi[11] ~ gamma(30.9, 33.2)    ;//ILB (defensive end and tackle)
phi[12] ~ gamma(53.5, 39.0)    ;//OLB (all linebackers) not quite converged
phi[13] ~ gamma(52.5, 48.2)    ;//CB not quite converged
phi[14] ~ gamma(53.5, 62.5)    ;//SCB not quite converged
phi[15] ~ gamma(14.1, 14.5)    ;//FS not quite converged
 
//prior player  mean hyperpriors

alpha ~ normal(-0.035,0.01);



// prior for Home Field Advantage (per play) 
u ~ normal(0, 1); 

// prior for play type 
g ~ normal(0, sqrt(s2playType));

s2playType ~ gamma(0.1, 1);

s2model ~ gamma(30,15);


// likelihood contribution
for(i in 1:N){

mu[i] = eta[i] + home[i]*u + g[playType[i]]    ; // + home[i]*uINT[playType[i]] add interaction playtype and home effect

y[i]~normal(mu[i], sqrt(s2model[playType[i]])); // different variances for different playtypes (run v. pass)

}

}

