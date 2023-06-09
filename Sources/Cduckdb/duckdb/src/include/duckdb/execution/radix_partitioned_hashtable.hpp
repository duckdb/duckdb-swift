//===----------------------------------------------------------------------===//
//                         DuckDB
//
// duckdb/execution/radix_partitioned_hashtable.hpp
//
//
//===----------------------------------------------------------------------===//

#pragma once

#include "duckdb/execution/operator/aggregate/grouped_aggregate_data.hpp"
#include "duckdb/execution/partitionable_hashtable.hpp"
#include "duckdb/execution/physical_operator.hpp"
#include "duckdb/parser/group_by_node.hpp"

namespace duckdb {
class BufferManager;
class Executor;
class PhysicalHashAggregate;
class Pipeline;
class Task;

class RadixPartitionedHashTable {
public:
	RadixPartitionedHashTable(GroupingSet &grouping_set, const GroupedAggregateData &op);

	GroupingSet &grouping_set;
	//! The indices specified in the groups_count that do not appear in the grouping_set
	unsafe_vector<idx_t> null_groups;
	const GroupedAggregateData &op;

	vector<LogicalType> group_types;
	//! how many groups can we have in the operator before we switch to radix partitioning
	idx_t radix_limit;

	//! The GROUPING values that belong to this hash table
	vector<Value> grouping_values;

public:
	//! Sink Interface
	unique_ptr<GlobalSinkState> GetGlobalSinkState(ClientContext &context) const;
	unique_ptr<LocalSinkState> GetLocalSinkState(ExecutionContext &context) const;

	void Sink(ExecutionContext &context, DataChunk &chunk, OperatorSinkInput &input, DataChunk &aggregate_input_chunk,
	          const unsafe_vector<idx_t> &filter) const;
	void Combine(ExecutionContext &context, GlobalSinkState &state, LocalSinkState &lstate) const;
	bool Finalize(ClientContext &context, GlobalSinkState &gstate_p) const;

	void ScheduleTasks(Executor &executor, const shared_ptr<Event> &event, GlobalSinkState &state,
	                   vector<shared_ptr<Task>> &tasks) const;

	//! Source interface
	idx_t Size(GlobalSinkState &sink_state) const;
	unique_ptr<GlobalSourceState> GetGlobalSourceState(ClientContext &context) const;
	unique_ptr<LocalSourceState> GetLocalSourceState(ExecutionContext &context) const;
	SourceResultType GetData(ExecutionContext &context, DataChunk &chunk, GlobalSinkState &sink_state,
	                         OperatorSourceInput &input) const;

	static void SetMultiScan(GlobalSinkState &state);
	static bool ForceSingleHT(GlobalSinkState &state);
	static bool AnyPartitioned(GlobalSinkState &state);
	static void GetRepartitionInfo(ClientContext &context, GlobalSinkState &state, idx_t &repartition_radix_bits,
	                               idx_t &concurrent_repartitions, idx_t &tasks_per_partition);

private:
	void SetGroupingValues();
	void PopulateGroupChunk(DataChunk &group_chunk, DataChunk &input_chunk) const;
	void InitializeFinalizedHTs(ClientContext &context, GlobalSinkState &state) const;
	void ScheduleRepartitionTasks(Executor &executor, const shared_ptr<Event> &event, GlobalSinkState &state,
	                              vector<shared_ptr<Task>> &tasks, const idx_t repartition_radix_bits,
	                              const idx_t concurrent_repartitions, const idx_t tasks_per_partition) const;
};

} // namespace duckdb
