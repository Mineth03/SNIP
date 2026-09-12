-- Additional policies for storage objects and buckets deletion & management

CREATE POLICY storage_buckets_select ON storage.buckets
  FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY storage_avatars_delete ON storage.objects
  FOR DELETE TO authenticated USING (
    bucket_id = 'avatars' AND auth.uid()::TEXT = (storage.foldername(name))[1]
  );

CREATE POLICY storage_salon_images_delete ON storage.objects
  FOR DELETE TO authenticated USING (
    bucket_id = 'salon-images'
  );

CREATE POLICY storage_salon_images_update ON storage.objects
  FOR UPDATE TO authenticated USING (
    bucket_id = 'salon-images'
  );

CREATE POLICY storage_service_images_delete ON storage.objects
  FOR DELETE TO authenticated USING (
    bucket_id = 'service-images'
  );

CREATE POLICY storage_barber_portfolios_delete ON storage.objects
  FOR DELETE TO authenticated USING (
    bucket_id = 'barber-portfolios'
  );
