/*
 * Copyright (c) 2020 ThoughtWorks Inc.
 */

#ifndef MATCH_ENGINE_INCLUDE_MATCH_ENGINE_GRPC_IMPL_H_
#define MATCH_ENGINE_INCLUDE_MATCH_ENGINE_GRPC_IMPL_H_

#include <grpcpp/server.h>

#include <memory>

#include <caf/all.hpp>

#include "./match_engine_cluster.h"
#include "./match_engine_config.h"

namespace match_engine {

class MatchEngineGRPCImpl final
    : public match_engine_proto::TradingEngine::Service,
      public SenderMatchInterface {
 public:
  grpc::Status Match(::grpc::ServerContext *context,
                     const ::match_engine_proto::Order *request,
                     ::match_engine_proto::Reply *response) override;
  grpc::Status SubscribeMatchResult(
      ::grpc::ServerContext *context, const ::google::protobuf::Empty *request,
      ::grpc::ServerWriter<::match_engine_proto::Trade> *writer) override;
  grpc::Status OpenCloseEngine(::grpc::ServerContext *context,
                               const ::match_engine_proto::EngineSwitch *status,
                               ::match_engine_proto::Reply *response) override;

  grpc::Status GetStats(::grpc::ServerContext *context,
                        const ::google::protobuf::Empty *request,
                        ::match_engine_proto::Stat *response) override;

  void Run();
  void RunWithWait();
  void SendMatchResult(const TradeList &trade_list) override;
  MatchEngineGRPCImpl(uint64_t server_port,
                      MatchEngineCluster &match_engine_cluster,
                      bool is_test = false);

 private:
  uint64_t server_port_;
  std::unique_ptr<grpc::Server> server_;
  MatchEngineCluster &match_engine_cluster_;
  MatchResultWriteKeepers match_result_writer_keepers{};
  bool is_test_ = false;
  std::atomic_bool engine_is_open_ = true;

  std::atomic_long received_order_count = 0;
  std::atomic_long generated_trade_count = 0;
};

}  // namespace match_engine

#endif  // MATCH_ENGINE_INCLUDE_MATCH_ENGINE_GRPC_IMPL_H_
