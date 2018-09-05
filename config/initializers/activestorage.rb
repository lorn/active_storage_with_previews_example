module ActiveStorageWithPreviewsExample
  class Application < Rails::Application

    config.cloudfront_host = ENV["CLOUDFRONT_HOST"]
    
    config.after_initialize do
      if defined?(ActiveStorage::Service::S3Service)
        ActiveStorage::Service::S3Service.class_eval do
          def cloudfront_host
            @cloudflront_host ||= Rails.configuration.cloudfront_host
          end

          def proxy_url(url)
            return url unless cloudfront_host
            uri = URI(url)
            uri.host = cloudfront_host
            uri.path.gsub!("/#{bucket.name}","")
            uri.to_s
          end

          def upload(key, io, checksum: nil)
            instrument :upload, key: key, checksum: checksum do
              begin
                object_for(key).put(upload_options.merge(body: io, content_md5: checksum, acl: 'public-read'))
              rescue Aws::S3::Errors::BadDigest
                raise ActiveStorage::IntegrityError
              end
            end
          end

          def url(key, expires_in: nil, filename: nil, disposition: nil, content_type: nil)
            instrument :url, key: key do |payload|
              generated_url = proxy_url object_for(key).public_url
              payload[:url] = generated_url
              generated_url
            end
          end
        end
      end
    end
  end
end
