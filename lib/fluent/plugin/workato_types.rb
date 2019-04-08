module Fluent::Plugin
  module WorkatoTypes
    TYPES = [
      { path: %w(recipe_cursor next_poll), type: Hash },
      { path: %w(recipe_cursor digest), type: String },
      { path: %w(recipe_cursor cursor), type: String },
      { path: %w(recipe_cursor created_at), type: DateTime },
      { path: %w(recipe_cursor after), type: DateTime },
      { path: %w(recipe_cursor events_in_progress:size), type: Float },
      # { path: 'recipe_cursor.events_in_progress:[]:size', 'type': Float },
      { path: %w(recipe_cursor next_page), type: 'Boolean' },
      { path: %w(recipe_cursor document_id), type: Float },
      { path: %w(recipe_cursor latest_updated_time), type: Integer },
      { path: %w(recipe_cursor last_id), type: Integer },
      { path: %w(recipe_cursor earliest_mtime), type: Integer },
      { path: %w(recipe_cursor since), type: DateTime },
      { path: %w(job args), type: Hash },
      { path: %w(error), type: Hash },
      { path: %w(choices), type: String },
      { path: %w(state), type: String },
      { path: %w(status), type: Integer },
      { path: %w(PID), type: Float },
      { path: %w(errno), type: Float },
      { path: %w(question_text), type: String },
      { path: %w(ID), type: Float },
      { path: %w(id), type: Float },
      { path: %w(errorCode), type: Float },
      { path: %w(code), type: Float },
      { path: %w(from), type: Float },
      { path: %w(errors), type: Hash },
      { path: %w(i), type: Float },
      { path: %w(o), type: String },
      { path: %w(error message), type: String },
      { path: %w(signaled_slots_counter), type: Float }
    ]
  end
end
