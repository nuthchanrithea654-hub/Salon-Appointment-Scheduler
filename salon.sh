#! /bin/bash

PSQL="psql --username=freecodecamp --dbname=salon -t --no-align -c"

echo "~~~~~ MY SALON ~~~~~"
echo
echo "Welcome to My Salon, how can I help you?"
echo

MAIN_MENU() {
  if [[ -n "$1" ]]; then
    echo
    echo "$1"
  fi

  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")

  while IFS="|" read -r SERVICE_ID SERVICE_NAME
  do
    if [[ -n "$SERVICE_ID" ]]; then
      echo "$SERVICE_ID) $SERVICE_NAME"
    fi
  done <<< "$SERVICES"

  read SERVICE_ID_SELECTED || return

  if [[ ! "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]; then
    MAIN_MENU "I could not find that service. What would you like today?"
    return
  fi

  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")

  if [[ -z "$SERVICE_NAME" ]]; then
    MAIN_MENU "I could not find that service. What would you like today?"
    return
  fi

  echo
  echo "What's your phone number?"
  read CUSTOMER_PHONE || return

  PHONE_SQL=$(printf '%s' "$CUSTOMER_PHONE" | sed "s/'/''/g")

  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$PHONE_SQL'")

  if [[ -z "$CUSTOMER_ID" ]]; then
    echo
    echo "I don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME || return

    NAME_SQL=$(printf '%s' "$CUSTOMER_NAME" | sed "s/'/''/g")

    $PSQL "INSERT INTO customers (name, phone) VALUES ('$NAME_SQL', '$PHONE_SQL')" || return

    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$PHONE_SQL'")
  else
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID")
  fi

  echo
  echo "What time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
  read SERVICE_TIME || return

  TIME_SQL=$(printf '%s' "$SERVICE_TIME" | sed "s/'/''/g")

  $PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$TIME_SQL')" || return

  echo
  echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
}

MAIN_MENU
