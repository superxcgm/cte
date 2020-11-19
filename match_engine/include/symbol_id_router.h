/*
 * Copyright (c) 2020 ThoughtWorks Inc.
 */

#ifndef MATCH_ENGINE_INCLUDE_SYMBOL_ID_ROUTER_H_
#define MATCH_ENGINE_INCLUDE_SYMBOL_ID_ROUTER_H_

#include <iostream>
#include <map>
#include <string>
#include <vector>

#include <caf/all.hpp>

#include "./match_engine_config.h"
namespace match_engine {

struct SymbolRouterData {
  std::map<int32_t, caf::actor> symbol_actor_map;
  std::map<std::string, std::vector<int32_t> > node_symbol_map;
  std::vector<SymbolActorInfo> local_symbol_actors;
  caf::actor get_stats_destination;
  std::vector<Stats> get_stats_results;
};

caf::behavior SymbolRouterActor(caf::stateful_actor<SymbolRouterData>* self);
}  // namespace match_engine
#endif  // MATCH_ENGINE_INCLUDE_SYMBOL_ID_ROUTER_H_
