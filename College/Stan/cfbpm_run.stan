data {
  int<lower=1> N; //number of data points
  real y[N]; //response variable, y is a set of integers
  real pmReplace;//replacement level plus-minus for all players
  
  //int<lower=0, upper = 1> pass[N]; //variable denoting if play was a pass  then 1 for offense else 0
  //int<lower=0, upper = 1> run[N]; //variable denoting if play was a run  then 1 for offense else 0
  int<lower=-1, upper = 1> home[N]; // variable denoting home/away/neutral (-1 for away, 0 for neutral, 1 for home)
  
  int<lower=1> nPlayers; //number of Players
  int<lower=1, upper=nPlayers> PlayerID[nPlayers]; //player id
  
  int<lower=1> nPlayType; //number of different play types
  int<lower=1, upper=nPlayType> playType[N]; //variable denoting what type of play it was
  
  
  int<lower=1> nPosition; //number of unique position groups
  int<lower=1, upper=nPosition> positions[nPlayers]; //the main position for each player
  
  int<lower=1> nPlayerPlays; //total number of plays by all players (should be about nPlayers*N)
  
  vector[nPlayers] recGrade     ; //recruiting grade -1 is missing -2 is less than cutofff-- only above 50 is a real grade
  vector[nPlayers] recGradeUse  ; // grade is useable (greater than 60 and not missing)
  vector[nPlayers] QBind        ; // Whether or not player is listed as a QB

  vector [nPlayerPlays] wX; // values of sparse design matrix
  int <lower = 1> vX[nPlayerPlays]; // column indicators of sparse matrix
  int <lower = 1> uX[N+1]; // row indicators of sparse matrix
  
  matrix<lower =0, upper = 1>[nPlayers, nPosition] posMat;//Matrix of fraction of time each player spends at each position
  
}
  
  
  
transformed data {
  
}
  
parameters {
  vector[nPlayers] b; //player intercepts
  
  real u; // effect for home field on a per play basis 

  vector<lower=0>[nPosition] phi; // multiplicative adjustment to variance of player mean by position (different one for each main position - serves as different shrinkage parameters)
  
  //vector[3] playerB; // coefficients for player priors 
  
  real<lower=0> s2model; //model variance
  real<lower=0> s2player; //across player variance

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
  positionVarCoef = posMat*phi;
  
  playerPriorMean = (-0.0733 + QBind*0.02422 + recGrade*0.000524 - recGradeUse*0.036944);  //recruiting information
                    
  
  //playerPriorMean = -0.0733 + QBind*playerB[1] + recGrade*playerB[2] + recGradeUse*playerB[3];
  // since s2player is about 1, each player's prior mean has weight roughly equal to one play unless adjusted
  // will be weighting last year to be 0.05*plysLastYr so that high volume guys have less than 10% of last years weight by end of year
  // If last year plays > 20 then divide by weighting, else keep the same std dev/variance/precision
  b ~ student_t(8, playerPriorMean, positionVarCoef*sqrt(s2player)) ;
  //b~normal(playerPriorMean, positionVarCoef * sqrt(s2player));
  
  
  s2player ~ gamma(0.5 , 90); // in a later version I may be able to change 0.03 and 10 to their own parameters
  
  //player prior mean coefficients
  //playerB[1] ~ normal(0.02422, 0.005);//bump in prior if you are a qb (recruiting grades more accurate for QB's)
  //playerB[2] ~ normal(0.000524, 0.00012);//slope if you have a recruiting grade (minimum is 60 )
  //playerB[3] ~ normal(-0.036944, 0.0075);//intercept if you have a recruiting grade
  
  //Different variances per position (each player gets 1 dominant position)
  phi[1] ~  gamma(54.6, 15.5)    ;//QB 0.1,25
  phi[2] ~  gamma(10.1, 12.4)    ;//RB (Runnning back and fullback)
  phi[3] ~  gamma(12.8, 11.3)    ;//SWR (slot receivers)
  phi[4] ~  gamma(13, 9.92)      ;//WR (non-slot wide receivers)
  phi[5] ~  gamma(3.54, 28.8)    ;//TE not quite converged
  phi[6] ~  gamma(125, 100)      ;//OT (tackle)
  phi[7] ~  gamma(47.6, 44.3)    ;//OG (guard)
  phi[8] ~  gamma(52.8, 29.8)    ;//C (center)
  phi[9] ~  gamma(71.4, 76.1)    ;//DT (defensive tackle)
  phi[10] ~ gamma(20.9, 20.9)    ;//DE (defensive end)
  phi[11] ~ gamma(107, 77.9)     ;//OLB (outside linebacker)
  phi[12] ~ gamma(61.8, 66.4)    ;//ILB (inside linebacker)
  phi[13] ~ gamma(107, 125)      ;//SCB (slot cornerback)
  phi[14] ~ gamma(105, 96.4)     ;//CB (cornerback)
  phi[15] ~ gamma(28.2, 28.9)    ;//S (safety)
  
  
  // prior for Home Field Advantage (per play) 
  u ~ normal(0.1, 1); 
  
  s2model ~ gamma(30,15);
  
  
  // likelihood contribution
  for(i in 1:N){
  
    //mu[i] = eta[i] + u    ; // u[2]*pass[i]
    mu[i] = eta[i] + home[i]*u   ; // 
    
    y[i]~normal(mu[i], sqrt(s2model));
  
  }
  
}