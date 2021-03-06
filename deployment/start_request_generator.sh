#!/usr/bin/env bash

i=0
cte_total_trade_number=0
ate_total_trade_number=0

cd /bin
/bin/create_initial_prices
echo "[$(date "+%Y-%m-%d %T.%3N")] [info] initial prices are generated"
echo "[$(date "+%Y-%m-%d %T.%3N")] [info] initial prices are generated" >>/tmp/log/long_run_status.log

while true; do
  #  curl -POST http://172.30.28.8:8086/query -s --data-urlencode "q=DROP DATABASE order_manager"
  #  curl -POST http://172.30.28.8:8086/query -s --data-urlencode "q=DROP DATABASE trade_manager"

  # 初始化
  echo "[$(date "+%Y-%m-%d %T.%3N")] [info] round $i starts"
  echo "[$(date "+%Y-%m-%d %T.%3N")] [info] round $i starts" >>/tmp/log/long_run_status.log

  #  if [[ $i -eq 0 ]]; then
  curl -POST http://172.30.28.30:8086/query -s --data-urlencode "q=DROP DATABASE orders"
  curl -POST http://172.30.28.30:8086/query -s --data-urlencode "q=DROP DATABASE akka_order_manager"
  curl -POST http://172.30.28.30:8086/query -s --data-urlencode "q=DROP DATABASE cte_order_manager"
  curl -POST http://172.30.28.30:8086/query -s --data-urlencode "q=DROP DATABASE trade_manager"

  curl -POST http://172.30.28.30:8086/query -s --data-urlencode "q=CREATE DATABASE akka_order_manager"
  curl -POST http://172.30.28.30:8086/query -s --data-urlencode "q=CREATE DATABASE cte_order_manager"
  curl -POST http://172.30.28.30:8086/query -s --data-urlencode "q=CREATE DATABASE trade_manager"
  #  fi

  cd /bin
  /bin/create_orders initial_prices.json test_env_create_orders_config.json
  echo "[$(date "+%Y-%m-%d %T.%3N")] [info] initial orders are generated"
  echo "[$(date "+%Y-%m-%d %T.%3N")] [info] initial orders are generated" >>/tmp/log/long_run_status.log

  # 判断上一轮是否有残留
  cte_trades_count=$(curl -GET 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode "db=trade_manager" --data-urlencode "q=SELECT count(symbol_id) FROM cte_trades" | python -c 'import json,sys;obj=json.load(sys.stdin); print(obj["results"][0]["series"][0]["values"][0][1])')
  akka_te_trades_count=$(curl -GET 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode "db=trade_manager" --data-urlencode "q=SELECT count(symbol_id) FROM akka_te_trades" | python -c 'import json,sys;obj=json.load(sys.stdin); print(obj["results"][0]["series"][0]["values"][0][1])')

  echo "[$(date "+%Y-%m-%d %T.%3N")] [info] cte_trades_count: ${cte_trades_count}"
  echo "[$(date "+%Y-%m-%d %T.%3N")] [info] cte_trades_count: ${cte_trades_count}" >>/tmp/log/long_run_status.log
  echo "[$(date "+%Y-%m-%d %T.%3N")] [info] akka_te_trades_count: ${akka_te_trades_count}"
  echo "[$(date "+%Y-%m-%d %T.%3N")] [info] akka_te_trades_count: ${akka_te_trades_count}" >>/tmp/log/long_run_status.log

  echo "[$(date "+%Y-%m-%d %T.%3N")] [info] start generating $NUM_OF_REQUEST requests to cte and akka-te"
  echo "[$(date "+%Y-%m-%d %T.%3N")] [info] start generating $NUM_OF_REQUEST requests to cte and akka-te" >>/tmp/log/long_run_status.log

  # 启动请求模拟器
  /bin/request_generator_main -n $NUM_OF_REQUEST -f test_env_cte_request_generator_config.json &
  cte_pid=$!
  /bin/request_generator_main -n $NUM_OF_REQUEST -f test_env_akka_request_generator_config.json
  echo "[$(date "+%Y-%m-%d %T.%3N")] [info] akka-te is finished, waiting for database service"
  echo "[$(date "+%Y-%m-%d %T.%3N")] [info] akka-te is finished, waiting for database service" >>/tmp/log/long_run_status.log

  # 判断 cte 撮合是否结束
  while true; do
    PID_EXIST=$(ps aux | awk '{print $2}' | grep -w $cte_pid)
    if [ ! $PID_EXIST ]; then
      echo "[$(date "+%Y-%m-%d %T.%3N")] [info] cte is finished, waiting for database service"
      echo "[$(date "+%Y-%m-%d %T.%3N")] [info] cte is finished, waiting for database service" >>/tmp/log/long_run_status.log
      break
    fi
    echo "[$(date "+%Y-%m-%d %T.%3N")] [info] cte is still running, try sleep 30 seconds..."
    echo "[$(date "+%Y-%m-%d %T.%3N")] [info] cte is still running, try sleep 30 seconds..." >>/tmp/log/long_run_status.log
    sleep 30
  done

  # 当 cte 撮合结束，开始判断 cte 是否写库结束
  while true; do
    count1=$(curl -GET 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode "db=trade_manager" --data-urlencode "q=SELECT count(symbol_id) FROM cte_trades" | python -c 'import json,sys;obj=json.load(sys.stdin); print(obj["results"][0]["series"][0]["values"][0][1])')
    sleep 15
    count2=$(curl -GET 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode "db=trade_manager" --data-urlencode "q=SELECT count(symbol_id) FROM cte_trades" | python -c 'import json,sys;obj=json.load(sys.stdin); print(obj["results"][0]["series"][0]["values"][0][1])')
    if [ $count1 == $count2 ]; then
      echo "[$(date "+%Y-%m-%d %T.%3N")] [info] cte database is available now"
      echo "[$(date "+%Y-%m-%d %T.%3N")] [info] cte database is available now" >>/tmp/log/long_run_status.log
      cte_total_trade_number=$((cte_total_trade_number + count1))
      echo "[$(date "+%Y-%m-%d %T.%3N")] [info] cte total trade number till now: ${cte_total_trade_number}"
      echo "[$(date "+%Y-%m-%d %T.%3N")] [info] cte total trade number till now: ${cte_total_trade_number}" >>/tmp/log/long_run_status.log
      break
    fi
    echo "[$(date "+%Y-%m-%d %T.%3N")] [info] cte database is still busy, try to sleep 15 seconds..."
    echo "[$(date "+%Y-%m-%d %T.%3N")] [info] cte database is still busy, try to sleep 15 seconds..." >>/tmp/log/long_run_status.log
  done

  # 判断 akka 是否写库结束
  while true; do
    count1=$(curl -GET 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode "db=trade_manager" --data-urlencode "q=SELECT count(symbol_id) FROM akka_te_trades" | python -c 'import json,sys;obj=json.load(sys.stdin); print(obj["results"][0]["series"][0]["values"][0][1])')
    sleep 15
    count2=$(curl -GET 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode "db=trade_manager" --data-urlencode "q=SELECT count(symbol_id) FROM akka_te_trades" | python -c 'import json,sys;obj=json.load(sys.stdin); print(obj["results"][0]["series"][0]["values"][0][1])')
    if [ $count1 == $count2 ]; then
      echo "[$(date "+%Y-%m-%d %T.%3N")] [info] akka_te database is available now"
      echo "[$(date "+%Y-%m-%d %T.%3N")] [info] akka_te database is available now" >>/tmp/log/long_run_status.log

      ate_total_trade_number=$((ate_total_trade_number + count1))
      echo "[$(date "+%Y-%m-%d %T.%3N")] [info] ate total trade number till now: ${ate_total_trade_number}"
      echo "[$(date "+%Y-%m-%d %T.%3N")] [info] ate total trade number till now: ${ate_total_trade_number}" >>/tmp/log/long_run_status.log
      break
    fi
    echo "[$(date "+%Y-%m-%d %T.%3N")] [info] akka_te database is still busy, try to sleep 15 seconds..."
    echo "[$(date "+%Y-%m-%d %T.%3N")] [info] akka_te database is still busy, try to sleep 15 seconds..." >>/tmp/log/long_run_status.log
  done

  # 启动数据验证器
  echo "[$(date "+%Y-%m-%d %T.%3N")] [info] start data_verifier now"
  echo "[$(date "+%Y-%m-%d %T.%3N")] [info] start data_verifier now" >>/tmp/log/long_run_status.log
  cd /tmp
  /tmp/data_verifier
  result=$?
  check_result=0
  if [[ $result -ne $check_result ]]; then
    break
  fi

  i=$((i + 1))

  #  curl -POST 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode 'db=orders' -s --data-urlencode "q=select * into orders_backup_${i} from orders"
  #  curl -POST 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode 'db=orders' -s --data-urlencode "q=drop measurement orders"
  #
  #  curl -POST 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode 'db=cte_order_manager' -s --data-urlencode 'q=select * into order_backup_'${i}' from "order"'
  #  curl -POST 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode 'db=cte_order_manager' -s --data-urlencode 'q=drop measurement "order"'
  #  curl -POST 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode 'db=akka_order_manager' -s --data-urlencode 'q=select * into order_backup_'${i}' from "order"'
  #  curl -POST 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode 'db=akka_order_manager' -s --data-urlencode 'q=drop measurement "order"'
  #
  #  curl -POST 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode 'db=trade_manager' -s --data-urlencode "q=select * into akka_te_trades_backup_${i} from akka_te_trades"
  #
  #  while true; do
  #    echo "[$(date "+%Y-%m-%d %T.%3N")] [info] start to clear akka_te_trades from trade_manager database"
  #    echo "[$(date "+%Y-%m-%d %T.%3N")] [info] start to clear akka_te_trades from trade_manager database" >>/tmp/log/long_run_status.log
  #    curl -POST 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode 'db=trade_manager' -s --data-urlencode "q=drop measurement akka_te_trades"
  #    count=$(curl -GET 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode "db=trade_manager" --data-urlencode "q=SELECT count(symbol_id) FROM akka_te_trades" | python -c 'import json,sys;obj=json.load(sys.stdin); print(obj["results"][0]["series"][0]["values"][0][1])')
  #    if [ -z "$count" ]; then
  #      echo "[$(date "+%Y-%m-%d %T.%3N")] [info] akka_te_trades cleared"
  #      echo "[$(date "+%Y-%m-%d %T.%3N")] [info] akka_te_trades cleared" >>/tmp/log/long_run_status.log
  #      break
  #    fi
  #  done
  #
  #  curl -POST 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode 'db=trade_manager' -s --data-urlencode "q=select * into cte_trades_backup_${i} from cte_trades"
  #
  #  while true; do
  #    echo "[$(date "+%Y-%m-%d %T.%3N")] [info] start to clear cte_trades from trade_manager database"
  #    echo "[$(date "+%Y-%m-%d %T.%3N")] [info] start to clear cte_trades from trade_manager database" >>/tmp/log/long_run_status.log
  #    curl -POST 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode 'db=trade_manager' -s --data-urlencode "q=drop measurement cte_trades"
  #    count=$(curl -GET 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode "db=trade_manager" --data-urlencode "q=SELECT count(symbol_id) FROM cte_trades" | python -c 'import json,sys;obj=json.load(sys.stdin); print(obj["results"][0]["series"][0]["values"][0][1])')
  #    if [ -z "$count" ]; then
  #      echo "[$(date "+%Y-%m-%d %T.%3N")] [info] cte_trades cleared"
  #      echo "[$(date "+%Y-%m-%d %T.%3N")] [info] cte_trades cleared" >>/tmp/log/long_run_status.log
  #      break
  #    fi
  #  done
  #
  #  # 备份数据库
  #  temp_num1=$(($i % 5))
  #  temp_num2=$(($i / 5))
  #  if [[ $temp_num1 -eq 0 && $temp_num2 -gt 2 ]]; then
  #    for j in {1..5}; do
  #      temp_num3=$(($i - 15 + $j))
  #      echo $i:$temp_num3
  #      echo $i:$temp_num3 >>/tmp/log/long_run_status.log
  #      curl -POST 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode 'db=orders' -s --data-urlencode "q=drop measurement orders_backup_${temp_num3}"
  #      curl -POST 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode 'db=cte_order_manager' -s --data-urlencode "q=drop measurement order_backup_${temp_num3}"
  #      curl -POST 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode 'db=akka_order_manager' -s --data-urlencode "q=drop measurement order_backup_${temp_num3}"
  #      curl -POST 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode 'db=trade_manager' -s --data-urlencode "q=drop measurement akka_te_trades_backup_${temp_num3}"
  #      curl -POST 'http://172.30.28.30:8086/query?pretty=true' -s --data-urlencode 'db=trade_manager' -s --data-urlencode "q=drop measurement cte_trades_backup_${temp_num3}"
  #    done
  #  fi
done
sleep infinity
