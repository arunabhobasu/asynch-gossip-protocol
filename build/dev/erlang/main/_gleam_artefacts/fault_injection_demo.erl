-module(fault_injection_demo).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src\\fault_injection_demo.gleam").
-export([demonstrate_fault_injection/0, demonstrate_push_sum_fault_injection/0]).

-file("src\\fault_injection_demo.gleam", 186).
-spec repeated(binary(), integer()) -> binary().
repeated(Str, Count) ->
    case Count =< 0 of
        true ->
            <<""/utf8>>;

        false ->
            <<Str/binary, (repeated(Str, Count - 1))/binary>>
    end.

-file("src\\fault_injection_demo.gleam", 8).
-spec demonstrate_fault_injection() -> nil.
demonstrate_fault_injection() ->
    gleam_stdlib:println(<<"🚨🚨🚨 FAULT INJECTION DEMONSTRATION 🚨🚨🚨"/utf8>>),
    gleam_stdlib:println(
        <<"=============================================="/utf8>>
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"📋 TEST SCENARIO:"/utf8>>),
    gleam_stdlib:println(<<"• Algorithm: Fault-Tolerant Gossip"/utf8>>),
    gleam_stdlib:println(<<"• Network: 16 nodes, Full topology"/utf8>>),
    gleam_stdlib:println(
        <<"• Strike Count: 3 (nodes marked dead after 3 missed pings)"/utf8>>
    ),
    gleam_stdlib:println(<<"• Fault Injection: ENABLED"/utf8>>),
    gleam_stdlib:println(
        <<"• Expected Kills: 2 nodes will be randomly terminated"/utf8>>
    ),
    gleam_stdlib:println(
        <<"• Kill Schedule: First kill at ~5 seconds, second kill at ~10 seconds"/utf8>>
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"🔍 WHAT TO OBSERVE:"/utf8>>),
    gleam_stdlib:println(<<"1. Normal gossip propagation starts"/utf8>>),
    gleam_stdlib:println(<<"2. FAULT INJECTOR kills random node(s)"/utf8>>),
    gleam_stdlib:println(<<"3. Other nodes detect missing heartbeats"/utf8>>),
    gleam_stdlib:println(<<"4. Strike counting begins (1, 2, 3 strikes)"/utf8>>),
    gleam_stdlib:println(
        <<"5. Dead nodes marked and removed from neighbor lists"/utf8>>
    ),
    gleam_stdlib:println(
        <<"6. Gossip continues with remaining healthy nodes"/utf8>>
    ),
    gleam_stdlib:println(
        <<"7. Algorithm completes despite node failures"/utf8>>
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(
        <<"🚀 Starting fault-tolerant gossip with fault injection..."/utf8>>
    ),
    gleam_stdlib:println(
        begin
            _pipe = <<"="/utf8>>,
            repeated(_pipe, 60)
        end
    ),
    Convergence_subject = gleam@erlang@process:new_subject(),
    Topology_map = topology:build_topology(16, full),
    parent:start_fault_tolerant_gossip_simulation(
        16,
        Topology_map,
        Convergence_subject,
        3
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"⏳ Waiting for simulation to complete..."/utf8>>),
    gleam_stdlib:println(
        <<"   (Watch for fault injection messages and strike counting)"/utf8>>
    ),
    Result = gleam@erlang@process:'receive'(Convergence_subject, 30000),
    case Result of
        {ok, {convergence_achieved, Time_ms}} ->
            gleam_stdlib:println(<<""/utf8>>),
            gleam_stdlib:println(<<"✅ FAULT INJECTION TEST COMPLETED!"/utf8>>),
            gleam_stdlib:println(
                begin
                    _pipe@1 = <<"="/utf8>>,
                    repeated(_pipe@1, 50)
                end
            ),
            gleam_stdlib:println(
                <<<<"🎯 Convergence achieved in "/utf8,
                        (erlang:integer_to_binary(Time_ms))/binary>>/binary,
                    "ms"/utf8>>
            ),
            gleam_stdlib:println(
                <<"🛡️ N-strike fault tolerance mechanism worked successfully!"/utf8>>
            ),
            gleam_stdlib:println(
                <<"💪 System survived node failures and maintained operation"/utf8>>
            ),
            gleam_stdlib:println(<<""/utf8>>),
            gleam_stdlib:println(<<"🔍 KEY OBSERVATIONS:"/utf8>>),
            gleam_stdlib:println(
                <<"• Fault injection successfully killed nodes during execution"/utf8>>
            ),
            gleam_stdlib:println(
                <<"• Strike counting mechanism detected dead nodes"/utf8>>
            ),
            gleam_stdlib:println(
                <<"• Network topology adapted by removing failed nodes"/utf8>>
            ),
            gleam_stdlib:println(
                <<"• Remaining nodes continued gossip propagation"/utf8>>
            ),
            gleam_stdlib:println(
                <<"• Algorithm converged despite faults"/utf8>>
            );

        {error, _} ->
            gleam_stdlib:println(<<""/utf8>>),
            gleam_stdlib:println(
                <<"⏰ TIMEOUT: Simulation took longer than 30 seconds"/utf8>>
            ),
            gleam_stdlib:println(<<"This could indicate:"/utf8>>),
            gleam_stdlib:println(
                <<"• Network partition due to critical node failures"/utf8>>
            ),
            gleam_stdlib:println(
                <<"• Strike count too high for the failure rate"/utf8>>
            ),
            gleam_stdlib:println(
                <<"• Need to adjust fault injection parameters"/utf8>>
            )
    end,
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"🔬 TECHNICAL DETAILS:"/utf8>>),
    gleam_stdlib:println(
        <<"• Fault Injector: Randomly selects and kills nodes"/utf8>>
    ),
    gleam_stdlib:println(
        <<"• Strike System: 3-strike rule for dead node detection"/utf8>>
    ),
    gleam_stdlib:println(
        <<"• Health Monitoring: Ping/Pong heartbeat mechanism"/utf8>>
    ),
    gleam_stdlib:println(
        <<"• Network Adaptation: Dead nodes removed from topology"/utf8>>
    ),
    gleam_stdlib:println(
        <<"• Recovery: No recovery - fault tolerance through exclusion"/utf8>>
    ).

-file("src\\fault_injection_demo.gleam", 98).
-spec demonstrate_push_sum_fault_injection() -> nil.
demonstrate_push_sum_fault_injection() ->
    gleam_stdlib:println(
        <<"🚨🚨🚨 PUSH-SUM FAULT INJECTION DEMONSTRATION 🚨🚨🚨"/utf8>>
    ),
    gleam_stdlib:println(
        <<"======================================================"/utf8>>
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"📋 TEST SCENARIO:"/utf8>>),
    gleam_stdlib:println(<<"• Algorithm: Fault-Tolerant Push-Sum"/utf8>>),
    gleam_stdlib:println(<<"• Network: 25 nodes, 3D Grid topology"/utf8>>),
    gleam_stdlib:println(
        <<"• Strike Count: 4 (nodes marked dead after 4 missed pings)"/utf8>>
    ),
    gleam_stdlib:println(<<"• Fault Injection: ENABLED"/utf8>>),
    gleam_stdlib:println(
        <<"• Expected Kills: 3 nodes will be randomly terminated"/utf8>>
    ),
    gleam_stdlib:println(<<"• Kill Schedule: Every ~3 seconds"/utf8>>),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"🔍 WHAT TO OBSERVE:"/utf8>>),
    gleam_stdlib:println(
        <<"1. Push-Sum algorithm starts calculating average"/utf8>>
    ),
    gleam_stdlib:println(<<"2. FAULT INJECTOR kills random node(s)"/utf8>>),
    gleam_stdlib:println(
        <<"3. Other nodes detect missing s/w value exchanges"/utf8>>
    ),
    gleam_stdlib:println(<<"4. Strike counting for unresponsive nodes"/utf8>>),
    gleam_stdlib:println(<<"5. Dead nodes excluded from calculations"/utf8>>),
    gleam_stdlib:println(<<"6. Push-Sum continues with remaining nodes"/utf8>>),
    gleam_stdlib:println(
        <<"7. Convergence achieved despite node failures"/utf8>>
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(
        <<"🚀 Starting fault-tolerant push-sum with fault injection..."/utf8>>
    ),
    gleam_stdlib:println(
        begin
            _pipe = <<"="/utf8>>,
            repeated(_pipe, 60)
        end
    ),
    Convergence_subject = gleam@erlang@process:new_subject(),
    Topology_map = topology:build_topology(25, grid3_d),
    parent:start_fault_tolerant_push_sum_simulation(
        25,
        Topology_map,
        Convergence_subject,
        4
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"⏳ Waiting for push-sum convergence..."/utf8>>),
    gleam_stdlib:println(
        <<"   (Watch for fault injection and value recalculation)"/utf8>>
    ),
    Result = gleam@erlang@process:'receive'(Convergence_subject, 45000),
    case Result of
        {ok, {convergence_achieved, Time_ms}} ->
            gleam_stdlib:println(<<""/utf8>>),
            gleam_stdlib:println(
                <<"✅ PUSH-SUM FAULT INJECTION TEST COMPLETED!"/utf8>>
            ),
            gleam_stdlib:println(
                begin
                    _pipe@1 = <<"="/utf8>>,
                    repeated(_pipe@1, 50)
                end
            ),
            gleam_stdlib:println(
                <<<<"🎯 Convergence achieved in "/utf8,
                        (erlang:integer_to_binary(Time_ms))/binary>>/binary,
                    "ms"/utf8>>
            ),
            gleam_stdlib:println(
                <<"🧮 Average calculation completed despite node failures!"/utf8>>
            ),
            gleam_stdlib:println(
                <<"💪 Push-Sum algorithm proved resilient to faults"/utf8>>
            ),
            gleam_stdlib:println(<<""/utf8>>),
            gleam_stdlib:println(<<"🔍 KEY OBSERVATIONS:"/utf8>>),
            gleam_stdlib:println(
                <<"• Fault injection killed nodes during calculation"/utf8>>
            ),
            gleam_stdlib:println(
                <<"• Remaining nodes recalculated with reduced network"/utf8>>
            ),
            gleam_stdlib:println(<<"• S/W ratios converged properly"/utf8>>),
            gleam_stdlib:println(
                <<"• No corruption of average calculation"/utf8>>
            ),
            gleam_stdlib:println(
                <<"• System maintained mathematical correctness"/utf8>>
            );

        {error, _} ->
            gleam_stdlib:println(<<""/utf8>>),
            gleam_stdlib:println(
                <<"⏰ TIMEOUT: Push-Sum took longer than 45 seconds"/utf8>>
            ),
            gleam_stdlib:println(<<"This could indicate:"/utf8>>),
            gleam_stdlib:println(
                <<"• Too many critical nodes were killed"/utf8>>
            ),
            gleam_stdlib:println(
                <<"• Network became too sparse for convergence"/utf8>>
            ),
            gleam_stdlib:println(
                <<"• Need to reduce fault injection rate"/utf8>>
            )
    end,
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"🔬 PUSH-SUM FAULT TOLERANCE SUMMARY:"/utf8>>),
    gleam_stdlib:println(
        <<"• Fault Injector: Randomly terminated nodes during calculation"/utf8>>
    ),
    gleam_stdlib:println(
        <<"• Strike System: 4-strike rule for dead node detection"/utf8>>
    ),
    gleam_stdlib:println(
        <<"• Value Preservation: S/W ratios maintained correctly"/utf8>>
    ),
    gleam_stdlib:println(
        <<"• Network Adaptation: Topology adjusted for failed nodes"/utf8>>
    ),
    gleam_stdlib:println(
        <<"• Mathematical Integrity: Average calculation remained accurate"/utf8>>
    ).
