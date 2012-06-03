/* 
   Perceptions
      Beginning:
        gsize(Weight,Height)
        steps(MaxSteps)
        corral(UpperLeft.x,UpperLeft.y,DownRight.x,DownRight.y)
        ag_perception_ratio(X). // ratio of perception of the agent
        
      Each step:
        pos(X,Y,Step)
        cow(Id,X,Y)
        ally_pos(Name,X,Y)

      End:
        end_of_simulation(Result)

*/

/* -- initial beliefs -- */

/* -- initial goals -- */

/* -- Plans -- */

+?pos(X, Y, S)
  <- .wait({+pos(X,Y,S)}).
  
+?gsize(W,H)
  <- .wait({+gsize(W,H)}).
  
+?group(team,G)
  <- .wait({+group(team,G)}, 500, _);
     ?group(team,G).
     
+?ally_pos(Name,X,Y) : .my_name(Name) <- ?pos(X,Y,_).

+corral(UpperLeftX,UpperLeftY,DownRightX,DownRightY)
  <- -+corral_center( (UpperLeftX + DownRightX)/2, (UpperLeftY + DownRightY)/2).
  
/* -- Rules -- */
  
corral_half_width(W)
  :- switch(X,Y) & jia.is_corral_switch(X,Y) &
     is_horizontal(X,Y) &
     corral(_UpperLeftX,UpperLeftY,_DownRightX,DownRightY) &   
     W = math.abs(UpperLeftY - DownRightY)/2.
   
corral_half_width(W)
  :- switch(X,Y) & jia.is_corral_switch(X,Y) &
     is_vertical(X,Y) &
     corral(UpperLeftX,_UpperLeftY,DownRightX,_DownRightY) &
     W = math.abs(UpperLeftX - DownRightX)/2.
   
@fimdesimulacao[atomic]
+end_of_simulation(_Result)
  <- -end_of_simulation(_);
     .drop_all_desires;
	 .abolish(cow(_,_,_));
     !remove_org.

+!restart
   : not .intend(restart) &
     .my_name(Me) & 
     not commitment(Me,_, _)
  <- .print("[gaucho.asl] Restarting the agent ", Me);
     !quit_all_missions_roles;
     !!start_being_dummy.


+!restart
   : .my_name(Me) &
     commitment(Me,Mis, _)
  <- .print("[gaucho.asl] Restart not applicable, I am committed to ",Mis).
  
+!restart
  <- .print("[gaucho.asl] Restart not applicable").
  
+!try_adopt(_Role,[]).

+!try_adopt(Role,[G|_])
  <- .print("[gaucho.asl] Adopting role ", Role, " in group ", G);
     jmoise.adopt_role(Role,G).
     
-!try_adopt(Role,[_|RG])
  <- .wait(500); 
     !try_adopt(Role,RG).

/* -- general organisational plans -- */

// remove all groups and schemes (only agent1 does that)
+!remove_org
   : .my_name(gaucho1)
  <- .print("[gaucho.asl] Removing all groups and schemes");
     if( group(team,Old) ) {
        jmoise.remove_group(Old)
     };
     
     for( scheme(_,SchId) ) {
        jmoise.remove_scheme(SchId)
     }.
     
+!remove_org.

  
// get the list G of participants of the group where I play R
+?my_group_players(G,R) 
  <- .my_name(Me);
     ?play(Me,R,Gid);
     .findall(P, play(P,_,Gid), G).


+!change_role(R,G)
   : .my_name(Me) &
     play(Me,R,G).
   
+!change_role(NewRole,GT)[source(S)]
	:not .intend(change_role(_,_))    
  <- .my_name(Me); 
	 .print("[gaucho.asl] Changing to role ",NewRole," in group ",GT,", as asked by ",S);
     !quit_all_missions_roles;
     jmoise.adopt_role(NewRole,GT).

+!change_role(_,_).


+!wait_no_players(R,G,GT)
   : not play(_,R,G)
  <- .print("[gaucho.asl] All the agents changed ").

+!wait_no_players(R,G,GT) 
  <- .findall(Ag,play(Ag,R,G),Ags);
	 .send(Ags, achieve, change_role(R,GT));
     .print("[gaucho.asl] Waiting agents ", Ags, " with role ", R, " to change from group ", G, " to group ", GT); 
     .wait(1000);
     !wait_no_players(R,G,GT).
  
+!quit_all_missions_roles
  <- .my_name(Me);
  
	 // if I play any other role, give it up
     while( play(Me,R,OG) ) {
        .print("[gaucho.asl] Removing my role ",R," in ",OG);
        jmoise.remove_role(R,OG)
     };
     
     // give up all missions
	 while( commitment(Me,M,Sch) ) {
        .print("[gaucho.asl] Removing my mission ",M," in ",Sch);
        jmoise.remove_mission(M,Sch)
	 }.
	 
-!quit_all_missions_roles[error_msg(M),code(C)]
  <- .println("[gaucho.asl] Error: ",C," - ",M). // no problem if it fails, it is better to continue

	 
+!remove_scheme_next_cicles(Sch)
  <- .wait( { +pos(_,_,_) } );
     .wait( { +pos(_,_,_) } );
     jmoise.remove_scheme(Sch).


// LINK TO MOISE, DO NOT TOUCH!

// when I have an obligation or permission to a mission, commit to it
+obligation(Sch, Mission) 
  <- .print("[gaucho.asl] Obligation to commit to mission ",Mission, " in scheme ", Sch);
     jmoise.commit_mission(Mission,Sch).
     
+permission(Sch, Mission)
  <- .print("[gaucho.asl] Permission to commit to mission ",Mission, " in scheme ", Sch);
     jmoise.commit_mission(Mission,Sch).

// when I am not committed to a mission anymore, remove all goals based on that mission
/*
-commitment(Me,Mission,Sch)
   : .my_name(Me)
  <- .print("[gaucho.asl] Removing all desires related to scheme ",Sch," and mission ",Mission);
     .drop_desire(_[scheme(Sch),mission(Mission)]).
*/
// if some scheme is finished, drop all intentions related to it.

-scheme(_Spec,Sch)
  <- .print("[gaucho.asl] Removing all desires related to scheme ",Sch);
     .drop_desire(_[scheme(Sch)]).
//     .abolish(_[scheme(Sch)]).


// If my group is removed, remove also the schemes	 

-group(_Spec,Gid)[owner(Me)]
   : .my_name(Me)
  <- while( scheme(_,SchId)[owner(Me)] & not scheme_group(SchId, _) ) {
	    .print("[gaucho.asl] Removing scheme (SchId: ", SchId, ") without responsible group");
	    jmoise.remove_scheme(SchId)
	 }.
	 


/* -- includes -- */
{ include("change.asl") }
{ include("goto.asl") }         // include plans for moving around

