# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class RemoveActiveChecklist < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    remove_column :checklists, :active
    Checklist.reset_column_information
  end
end
