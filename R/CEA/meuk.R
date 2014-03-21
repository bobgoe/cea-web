Transition <- array(, dim=c(2,2,2) ) # 2 alternatieven, dus 2 transitie matrices van 2 states die dus 2*2 zijn.
                                      # Eerste getal is de rij, tweede getal de kolom en het derde getal het alternatief.
alternativesAmount <- 2
statesAmount <- 2
  
# Eerste alternatief geeft baseline deterministisch aan, A-A = 0.75, A-B = 0.25, B-A = 0 en B-B = 1
Transition[1,1,1] <- 0.75 # A-A
Transition[1,2,1] <- 0.25 # A-B
Transition[2,1,1] <- 0 # B-A
Transition[2,2,1] <- 1 # B-B

# Tweede alternatief moet de relatieve effecten aangeven 
Transition[1,1,2] <- 0 # A-A gaan we berekenen
Transition[1,2,2] <- 0.8 # A-B geeft een reductie van 80%, dus dat wordt in harde getallen 0.25*0.8 = 0.2
Transition[2,1,2] <- 1 # B-A veranderd niet, dus 100%
Transition[2,2,2] <- 0 # B-B gaan we berekenen

sampledTransitionRates <- array(, dim=c(2,2,2) ) # Identiek aan de inputs, maar deze heeft harde getallen

for (alternative in 2:alternativesAmount){ # vanaf tweede alternatief want eerste is je baseline

    for (fromState in 1:statesAmount){
      
        for (toState in 1:statesAmount){
          
            if (fromState != toState){
              print(Transition[fromState, toState , 1 ] * Transition[fromState, toState , alternative ])
            }
        }
        
        print(1-sum(Transition[fromState,,alternative]))
    }
}