/*
 * Copyright (c) 2020 ThoughtWorks Inc.
 */

#ifndef TRADE_PERSISTENCE_TOOL_INCLUDE_TRADE_PERSISTENCE_CLIENT_H_
#define TRADE_PERSISTENCE_TOOL_INCLUDE_TRADE_PERSISTENCE_CLIENT_H_

#include <string>
#include <utility>
#include <vector>

#include "./database_write_interface.h"

class TradePersistenceClient {
 public:
  TradePersistenceClient(DatabaseWriteInterface* database,
                         const std::string& tradeEngineAddress)
      : database(database), trade_engine_address_(tradeEngineAddress) {}

  bool PersistTrades();

 private:
  DatabaseWriteInterface* database;
  std::string trade_engine_address_;
};

std::vector<std::string> ParseIpAddress(std::string address);

#endif  // TRADE_PERSISTENCE_TOOL_INCLUDE_TRADE_PERSISTENCE_CLIENT_H_
