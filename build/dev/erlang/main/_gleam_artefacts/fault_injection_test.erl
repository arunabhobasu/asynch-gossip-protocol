-module(fault_injection_test).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src\\fault_injection_test.gleam").
-export([test_fault_injection_basic/0, demonstrate_fault_injection_concept/0]).

-file("src\\fault_injection_test.gleam", 5).
-spec test_fault_injection_basic() -> nil.
test_fault_injection_basic() ->
    gleam_stdlib:println(<<"🚨 BASIC FAULT INJECTION TEST"/utf8>>),
    gleam_stdlib:println(<<"============================="/utf8>>),
    gleam_stdlib:println(<<"Test 1: Creating fault injector..."/utf8>>),
    case fault_injector:start_fault_injector(1000, 2) of
        {ok, Injector_started} ->
            Injector_subject = erlang:element(3, Injector_started),
            gleam_stdlib:println(
                <<"✅ Fault injector created successfully"/utf8>>
            ),
            gleam_stdlib:println(
                <<"Test 2: Triggering manual fault injection (no nodes)..."/utf8>>
            ),
            fault_injector:trigger_fault_now(Injector_subject),
            gleam_stdlib:println(<<"✅ Manual trigger sent"/utf8>>),
            gleam_stdlib:println(<<"Test 3: Stopping fault injection..."/utf8>>),
            fault_injector:deactivate_fault_injection(Injector_subject),
            gleam_stdlib:println(<<"✅ Fault injection deactivated"/utf8>>),
            gleam_stdlib:println(<<""/utf8>>),
            gleam_stdlib:println(
                <<"🎯 BASIC TEST COMPLETED SUCCESSFULLY!"/utf8>>
            ),
            gleam_stdlib:println(
                <<"The fault injection system is ready for use."/utf8>>
            );

        {error, _} ->
            gleam_stdlib:println(<<"❌ Failed to create fault injector"/utf8>>)
    end.

-file("src\\fault_injection_test.gleam", 36).
-spec demonstrate_fault_injection_concept() -> nil.
demonstrate_fault_injection_concept() ->
    gleam_stdlib:println(<<"🎓 FAULT INJECTION SYSTEM CONCEPT"/utf8>>),
    gleam_stdlib:println(<<"=================================="/utf8>>),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"📖 HOW THE FAULT INJECTION SYSTEM WORKS:"/utf8>>),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"1️⃣ SYSTEM ARCHITECTURE:"/utf8>>),
    gleam_stdlib:println(
        <<"   • Fault Injector Actor: Manages the killing of nodes"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   • Kill Schedule: Configurable delay between kills"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   • Target Selection: Random selection from active nodes"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   • Kill Mechanism: Sends 'Terminate' message to target nodes"/utf8>>
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"2️⃣ INTEGRATION WITH N-STRIKE SYSTEM:"/utf8>>),
    gleam_stdlib:println(
        <<"   • Fault injection creates real node failures"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   • N-strike system detects missing heartbeats"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   • Strike counting begins: 1 → 2 → 3 → DEAD"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   • Dead nodes are removed from neighbor lists"/utf8>>
    ),
    gleam_stdlib:println(<<"   • Network adapts and continues operation"/utf8>>),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"3️⃣ TESTING CAPABILITIES:"/utf8>>),
    gleam_stdlib:println(
        <<"   • Gossip Algorithm: Tests rumor propagation with failures"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   • Push-Sum Algorithm: Tests convergence with node deaths"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   • Multiple Topologies: Different network resilience patterns"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   • Configurable Parameters: Strike count, kill rate, max kills"/utf8>>
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"4️⃣ FAULT INJECTION PARAMETERS:"/utf8>>),
    gleam_stdlib:println(
        <<"   • Kill Delay: Time between successive node kills"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   • Max Kills: Maximum number of nodes to terminate"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   • Strike Count: How many missed heartbeats = dead"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   • Network Size: Affects fault tolerance threshold"/utf8>>
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"5️⃣ EXPECTED BEHAVIORS:"/utf8>>),
    gleam_stdlib:println(
        <<"   ✅ Normal Operation: Nodes communicate via heartbeats"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   💀 Fault Injection: Random node receives Terminate message"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   🔍 Detection Phase: Other nodes miss heartbeats from killed node"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   📊 Strike Counting: 1st miss → 2nd miss → Nth miss → DEAD"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   🛡️ Network Healing: Dead node removed from all neighbor lists"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   🔄 Continued Operation: Algorithm completes with remaining nodes"/utf8>>
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"6️⃣ KEY ADVANTAGES:"/utf8>>),
    gleam_stdlib:println(
        <<"   • Real Fault Testing: Actual node termination vs. simulation"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   • Timing Control: Precise control over when faults occur"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   • Scalable Testing: Works with any network size/topology"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   • Comprehensive Coverage: Tests both detection and recovery"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   • Production Readiness: Validates real-world fault scenarios"/utf8>>
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"7️⃣ USAGE COMMANDS:"/utf8>>),
    gleam_stdlib:println(
        <<"   gleam run fault-inject-gossip    # Test gossip with fault injection"/utf8>>
    ),
    gleam_stdlib:println(
        <<"   gleam run fault-inject-pushsum   # Test push-sum with fault injection"/utf8>>
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"🚀 READY TO TEST:"/utf8>>),
    gleam_stdlib:println(
        <<"The fault injection system is now integrated and ready!"/utf8>>
    ),
    gleam_stdlib:println(
        <<"Use the commands above to see N-strike fault tolerance in action."/utf8>>
    ),
    gleam_stdlib:println(
        <<"Watch for the 💀 FAULT INJECTION messages during execution."/utf8>>
    ).
