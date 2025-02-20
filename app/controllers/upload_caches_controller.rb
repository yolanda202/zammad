# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class UploadCachesController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  # POST /upload_caches/1
  def update
    file = params[:File]
    content_type = file.content_type
    if !content_type || content_type == 'application/octet-stream'
      mime_type    = MIME::Types.type_for(file.original_filename).first
      content_type = mime_type&.content_type || 'application/octet-stream'
    end
    headers_store = {
      'Content-Type' => content_type
    }

    store = cache.add(
      filename:      file.original_filename,
      data:          file.read,
      preferences:   headers_store,
      created_by_id: current_user.id
    )

    # return result
    render json: {
      success: true,
      data:    {
        id:          store.id, # TODO: rename?
        filename:    file.original_filename,
        size:        store.size,
        contentType: store.preferences['Content-Type']
      }
    }
  end

  # DELETE /upload_caches/1
  def destroy
    cache.destroy

    render json: {
      success: true,
    }
  end

  # DELETE /upload_caches/1/items/1
  def remove_item
    cache.remove_item(params[:store_id])

    render json: {
      success: true,
    }
  end

  private

  def cache
    UploadCache.new(params[:id])
  end
end
