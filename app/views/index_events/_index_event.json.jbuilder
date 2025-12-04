json.extract! index_event, :id, :name, :event_date, :user_id, :created_at, :updated_at
json.url index_event_url(index_event, format: :json)
