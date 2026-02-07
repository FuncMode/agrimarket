-- ============================================================================
-- AGRIMARKET SYSTEM - CONSOLIDATED DATABASE SCHEMA AND MIGRATIONS
-- Production-Ready with All Features and Performance Improvements
-- Generated: 2026-02-07
-- ============================================================================
-- This file contains the complete database schema and all migrations consolidated
-- into a single file for easier deployment and management.
-- ============================================================================

-- ============================================================================
-- DROP EXISTING TABLES (Uncomment for fresh installation)
-- ============================================================================
-- DROP TABLE IF EXISTS admin_logs CASCADE;
-- DROP TABLE IF EXISTS product_reviews CASCADE;
-- DROP TABLE IF EXISTS product_views CASCADE;
-- DROP TABLE IF EXISTS notifications CASCADE;
-- DROP TABLE IF EXISTS messages CASCADE;
-- DROP TABLE IF EXISTS issue_reports CASCADE;
-- DROP TABLE IF EXISTS order_items CASCADE;
-- DROP TABLE IF EXISTS orders CASCADE;
-- DROP TABLE IF EXISTS shopping_carts CASCADE;
-- DROP TABLE IF EXISTS product_tags CASCADE;
-- DROP TABLE IF EXISTS products CASCADE;
-- DROP TABLE IF EXISTS verification_documents CASCADE;
-- DROP TABLE IF EXISTS seller_profiles CASCADE;
-- DROP TABLE IF EXISTS buyer_profiles CASCADE;
-- DROP TABLE IF EXISTS users CASCADE;

-- ============================================================================
-- TABLE 1: USERS
-- ============================================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    role VARCHAR(20) NOT NULL CHECK (role IN ('buyer', 'seller', 'admin')),
    status VARCHAR(30) DEFAULT 'unverified' CHECK (status IN ('unverified', 'verification_pending', 'verified', 'rejected', 'suspended', 'banned')),
    verified_at TIMESTAMP,
    reset_token VARCHAR(255),
    reset_token_expires TIMESTAMP,
    suspension_end TIMESTAMP,
    ban_reason TEXT,
    agreed_to_terms BOOLEAN DEFAULT FALSE NOT NULL,
    agreed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_reset_token ON users(reset_token) WHERE reset_token IS NOT NULL;
CREATE INDEX idx_users_agreed_to_terms ON users(agreed_to_terms);

-- ============================================================================
-- TABLE 2: BUYER_PROFILES
-- ============================================================================
CREATE TABLE buyer_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    delivery_address TEXT,
    delivery_latitude DECIMAL(10, 8),
    delivery_longitude DECIMAL(11, 8),
    municipality VARCHAR(100),
    preferred_delivery_option VARCHAR(20) DEFAULT 'drop-off' CHECK (preferred_delivery_option IN ('pickup', 'drop-off')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_buyer_profiles_user ON buyer_profiles(user_id);
CREATE INDEX idx_buyer_profiles_municipality ON buyer_profiles(municipality);

-- ============================================================================
-- TABLE 3: SELLER_PROFILES
-- ============================================================================
CREATE TABLE seller_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    municipality VARCHAR(100) NOT NULL,
    farm_type VARCHAR(50) NOT NULL CHECK (farm_type IN ('farm', 'fishery', 'cooperative', 'other')),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    rating DECIMAL(3, 2) DEFAULT 0.00 CHECK (rating >= 0 AND rating <= 5),
    total_sales DECIMAL(12, 2) DEFAULT 0.00,
    total_orders INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_seller_profiles_user ON seller_profiles(user_id);
CREATE INDEX idx_seller_profiles_municipality ON seller_profiles(municipality);
CREATE INDEX idx_seller_profiles_farm_type ON seller_profiles(farm_type);
CREATE INDEX idx_seller_profiles_rating ON seller_profiles(rating DESC);

-- ============================================================================
-- TABLE 4: VERIFICATION_DOCUMENTS
-- ============================================================================
CREATE TABLE verification_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    id_photo_path TEXT NOT NULL,
    selfie_path TEXT NOT NULL,
    id_type VARCHAR(50) NOT NULL CHECK (id_type IN ('drivers_license', 'philid', 'passport', 'nbi_clearance')),
    submission_status VARCHAR(30) DEFAULT 'pending' CHECK (submission_status IN ('pending', 'approved', 'rejected', 'more_evidence')),
    admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    admin_notes TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_verification_user ON verification_documents(user_id);
CREATE INDEX idx_verification_status ON verification_documents(submission_status);
CREATE INDEX idx_verification_admin ON verification_documents(admin_id);
CREATE INDEX idx_verification_submitted ON verification_documents(submitted_at DESC);

-- ============================================================================
-- TABLE 5: PRODUCTS
-- ============================================================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID NOT NULL REFERENCES seller_profiles(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL CHECK (category IN ('vegetables', 'fruits', 'fish_seafood', 'meat_poultry', 'other')),
    price_per_unit DECIMAL(10, 2) NOT NULL CHECK (price_per_unit > 0),
    unit_type VARCHAR(20) NOT NULL CHECK (unit_type IN ('kg', 'pcs', 'bundle', 'box', 'dozen', 'liter', 'other')),
    available_quantity INTEGER NOT NULL CHECK (available_quantity >= 0),
    municipality VARCHAR(100) NOT NULL,
    photo_path TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'paused', 'draft', 'deleted')),
    view_count INTEGER DEFAULT 0,
    order_count INTEGER DEFAULT 0,
    average_rating DECIMAL(3, 2) DEFAULT 0.00 CHECK (average_rating >= 0 AND average_rating <= 5),
    total_reviews INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_seller ON products(seller_id);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_municipality ON products(municipality);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_created ON products(created_at DESC);
CREATE INDEX idx_products_price ON products(price_per_unit);
CREATE INDEX idx_products_seller_status ON products(seller_id, status);
CREATE INDEX idx_products_rating ON products(average_rating DESC NULLS LAST);
CREATE INDEX idx_products_search ON products USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '')));

-- ============================================================================
-- TABLE 6: PRODUCT_TAGS
-- ============================================================================
CREATE TABLE product_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    tag VARCHAR(50) NOT NULL CHECK (tag IN ('fresh', 'organic', 'farmed', 'wild_caught', 'recently_harvested', 'other')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_product_tag UNIQUE(product_id, tag)
);

CREATE INDEX idx_product_tags_product ON product_tags(product_id);
CREATE INDEX idx_product_tags_tag ON product_tags(tag);

-- ============================================================================
-- TABLE 7: SHOPPING_CARTS
-- ============================================================================
CREATE TABLE shopping_carts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    buyer_id UUID NOT NULL REFERENCES buyer_profiles(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    seller_id UUID NOT NULL REFERENCES seller_profiles(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price_snapshot DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_buyer_product UNIQUE(buyer_id, product_id)
);

CREATE INDEX idx_shopping_carts_buyer ON shopping_carts(buyer_id);
CREATE INDEX idx_shopping_carts_product ON shopping_carts(product_id);
CREATE INDEX idx_shopping_carts_seller ON shopping_carts(seller_id);
CREATE INDEX idx_shopping_carts_buyer_seller ON shopping_carts(buyer_id, seller_id);
CREATE INDEX idx_shopping_carts_updated ON shopping_carts(updated_at DESC);

-- ============================================================================
-- TABLE 8: ORDERS
-- ============================================================================
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    buyer_id UUID NOT NULL REFERENCES buyer_profiles(id) ON DELETE RESTRICT,
    seller_id UUID NOT NULL REFERENCES seller_profiles(id) ON DELETE RESTRICT,
    delivery_option VARCHAR(20) NOT NULL CHECK (delivery_option IN ('pickup', 'drop-off')),
    delivery_address TEXT,
    delivery_latitude DECIMAL(10, 8),
    delivery_longitude DECIMAL(11, 8),
    preferred_date DATE,
    preferred_time VARCHAR(50),
    order_notes TEXT,
    subtotal DECIMAL(10, 2) NOT NULL CHECK (subtotal > 0),
    delivery_fee DECIMAL(10, 2) DEFAULT 0.00 CHECK (delivery_fee >= 0),
    total_amount DECIMAL(10, 2) NOT NULL CHECK (total_amount > 0),
    payment_method VARCHAR(20) DEFAULT 'cod',
    payment_status VARCHAR(20) DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'paid')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'ready', 'completed', 'cancelled')),
    buyer_confirmed BOOLEAN DEFAULT FALSE,
    buyer_confirmed_at TIMESTAMP,
    seller_confirmed BOOLEAN DEFAULT FALSE,
    seller_confirmed_at TIMESTAMP,
    cancelled_by UUID REFERENCES users(id) ON DELETE SET NULL,
    cancellation_reason TEXT,
    seller_delivery_proof_url TEXT,
    buyer_delivery_proof_url TEXT,
    buyer_rating INTEGER CHECK (buyer_rating >= 1 AND buyer_rating <= 5),
    buyer_rating_comment TEXT,
    buyer_rated_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orders_buyer ON orders(buyer_id);
CREATE INDEX idx_orders_seller ON orders(seller_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created ON orders(created_at DESC);
CREATE INDEX idx_orders_number ON orders(order_number);
CREATE INDEX idx_orders_buyer_status ON orders(buyer_id, status);
CREATE INDEX idx_orders_seller_status ON orders(seller_id, status);
CREATE INDEX idx_orders_buyer_created ON orders(buyer_id, created_at DESC);
CREATE INDEX idx_orders_seller_created ON orders(seller_id, created_at DESC);
CREATE INDEX idx_orders_seller_proof ON orders(seller_delivery_proof_url) WHERE seller_delivery_proof_url IS NOT NULL;
CREATE INDEX idx_orders_buyer_proof ON orders(buyer_delivery_proof_url) WHERE buyer_delivery_proof_url IS NOT NULL;
CREATE INDEX idx_orders_buyer_rating ON orders(buyer_rating) WHERE buyer_rating IS NOT NULL;
CREATE INDEX idx_orders_seller_rating ON orders(seller_id, buyer_rating) WHERE buyer_rating IS NOT NULL;

-- Composite indexes for performance optimization
CREATE INDEX IF NOT EXISTS idx_orders_buyer_status_created ON orders(buyer_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_seller_status_created ON orders(seller_id, status, created_at DESC);

-- ============================================================================
-- TABLE 9: ORDER_ITEMS
-- ============================================================================
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price_per_unit DECIMAL(10, 2) NOT NULL CHECK (price_per_unit > 0),
    unit_type VARCHAR(20) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    subtotal DECIMAL(10, 2) NOT NULL CHECK (subtotal > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- ============================================================================
-- TABLE 10: PRODUCT_REVIEWS
-- ============================================================================
CREATE TABLE product_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    buyer_id UUID NOT NULL REFERENCES buyer_profiles(id) ON DELETE CASCADE,
    seller_id UUID NOT NULL REFERENCES seller_profiles(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure one review per product per order
    CONSTRAINT unique_order_product_review UNIQUE(order_id, product_id)
);

CREATE INDEX idx_product_reviews_product ON product_reviews(product_id);
CREATE INDEX idx_product_reviews_seller ON product_reviews(seller_id);
CREATE INDEX idx_product_reviews_buyer ON product_reviews(buyer_id);
CREATE INDEX idx_product_reviews_order ON product_reviews(order_id);
CREATE INDEX idx_product_reviews_created ON product_reviews(created_at DESC);

-- ============================================================================
-- TABLE 11: PRODUCT_VIEWS
-- ============================================================================
CREATE TABLE product_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL,
    buyer_id UUID NOT NULL,
    viewed_at TIMESTAMP DEFAULT NOW(),
    
    -- Foreign key constraints
    CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_buyer FOREIGN KEY (buyer_id) REFERENCES users(id) ON DELETE CASCADE,
    
    -- Unique constraint: each buyer can view each product only once (for counting purposes)
    CONSTRAINT unique_buyer_product_view UNIQUE(product_id, buyer_id)
);

CREATE INDEX idx_product_views_product_id ON product_views(product_id);
CREATE INDEX idx_product_views_buyer_id ON product_views(buyer_id);
CREATE INDEX idx_product_views_viewed_at ON product_views(viewed_at);

-- ============================================================================
-- TABLE 12: MESSAGES
-- ============================================================================
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message_text TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file')),
    attachment_path TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Optimized indexes for messages performance
CREATE INDEX idx_messages_order_id ON messages(order_id);
CREATE INDEX idx_messages_order_created ON messages(order_id, created_at DESC);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_unread_sender ON messages(is_read, sender_id) WHERE is_read = false;
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);

-- ============================================================================
-- TABLE 13: ISSUE_REPORTS
-- ============================================================================
CREATE TABLE issue_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    reported_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    issue_type VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    evidence_urls TEXT[],
    status VARCHAR(30) DEFAULT 'under_review' CHECK (status IN ('under_review', 'resolved', 'rejected')),
    resolution TEXT,
    admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_issue_reports_order ON issue_reports(order_id);
CREATE INDEX idx_issue_reports_reporter ON issue_reports(reported_by);
CREATE INDEX idx_issue_reports_status ON issue_reports(status);
CREATE INDEX idx_issue_reports_admin ON issue_reports(admin_id);
CREATE INDEX idx_issue_reports_created ON issue_reports(created_at DESC);

-- ============================================================================
-- TABLE 14: NOTIFICATIONS
-- ============================================================================
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    reference_id UUID,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC);

-- ============================================================================
-- TABLE 15: ADMIN_LOGS
-- ============================================================================
CREATE TABLE admin_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    action_type VARCHAR(50) NOT NULL,
    action_description TEXT NOT NULL,
    target_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    reference_id UUID,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_admin_logs_admin ON admin_logs(admin_id);
CREATE INDEX idx_admin_logs_type ON admin_logs(action_type);
CREATE INDEX idx_admin_logs_target ON admin_logs(target_user_id);
CREATE INDEX idx_admin_logs_created ON admin_logs(created_at DESC);
CREATE INDEX idx_admin_logs_admin_created ON admin_logs(admin_id, created_at DESC);

-- ============================================================================
-- ADDITIONAL COMPOSITE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Composite index for seller product lists
CREATE INDEX IF NOT EXISTS idx_products_seller_status_created ON products(seller_id, status, created_at DESC);

-- Composite index for getVerifiedSellers with filters
CREATE INDEX IF NOT EXISTS idx_seller_profiles_municipality_farm_type ON seller_profiles(municipality, farm_type);

-- Index on seller_profiles rating for sorting
CREATE INDEX IF NOT EXISTS idx_seller_profiles_rating_desc ON seller_profiles(rating DESC NULLS LAST);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to increment view count (atomic)
CREATE OR REPLACE FUNCTION increment_view_count(product_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE products 
    SET view_count = view_count + 1,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = product_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update product rating
CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
DECLARE
    product_avg_rating DECIMAL(3, 2);
    product_total_reviews INTEGER;
BEGIN
    -- Calculate average rating for this product
    SELECT 
        ROUND(AVG(rating)::numeric, 2),
        COUNT(*)
    INTO product_avg_rating, product_total_reviews
    FROM product_reviews
    WHERE product_id = NEW.product_id;
    
    -- Update product with new rating
    UPDATE products
    SET average_rating = COALESCE(product_avg_rating, 0.00),
        total_reviews = COALESCE(product_total_reviews, 0),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.product_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update seller rating from order ratings (legacy)
CREATE OR REPLACE FUNCTION update_seller_rating()
RETURNS TRIGGER AS $$
DECLARE
    seller_avg_rating DECIMAL(3, 2);
    seller_total_ratings INTEGER;
BEGIN
    -- Calculate average rating for this seller from all rated orders
    SELECT 
        ROUND(AVG(buyer_rating)::numeric, 2),
        COUNT(*)
    INTO seller_avg_rating, seller_total_ratings
    FROM orders
    WHERE seller_id = NEW.seller_id
    AND buyer_rating IS NOT NULL;
    
    -- Update seller profile with new rating
    UPDATE seller_profiles
    SET rating = COALESCE(seller_avg_rating, 0.00),
        total_orders = (SELECT COUNT(*) FROM orders WHERE seller_id = NEW.seller_id AND status = 'completed'),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.seller_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update seller rating from product reviews
CREATE OR REPLACE FUNCTION update_seller_rating_from_reviews()
RETURNS TRIGGER AS $$
DECLARE
    seller_avg_rating DECIMAL(3, 2);
    seller_total_ratings INTEGER;
BEGIN
    -- Calculate average rating for this seller from all product reviews
    SELECT 
        ROUND(AVG(rating)::numeric, 2),
        COUNT(*)
    INTO seller_avg_rating, seller_total_ratings
    FROM product_reviews
    WHERE seller_id = COALESCE(NEW.seller_id, OLD.seller_id);
    
    -- Update seller profile with new rating
    UPDATE seller_profiles
    SET rating = COALESCE(seller_avg_rating, 0.00),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = COALESCE(NEW.seller_id, OLD.seller_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Function for efficient unread counts by orders for messaging
CREATE OR REPLACE FUNCTION get_unread_counts_by_orders(
  order_ids UUID[],
  user_id UUID
)
RETURNS TABLE (
  order_id UUID,
  unread_count BIGINT
)
LANGUAGE sql
STABLE
AS $$
  SELECT 
    m.order_id,
    COUNT(m.id)::BIGINT as unread_count
  FROM messages m
  WHERE m.order_id = ANY(order_ids)
    AND m.is_read = false
    AND m.sender_id != user_id
  GROUP BY m.order_id;
$$;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Auto-update timestamps
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_buyer_profiles_updated_at
    BEFORE UPDATE ON buyer_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_seller_profiles_updated_at
    BEFORE UPDATE ON seller_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shopping_carts_updated_at
    BEFORE UPDATE ON shopping_carts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_verification_documents_updated_at
    BEFORE UPDATE ON verification_documents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_issue_reports_updated_at
    BEFORE UPDATE ON issue_reports
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_product_reviews_updated_at
    BEFORE UPDATE ON product_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Rating update triggers
CREATE TRIGGER trigger_update_product_rating
    AFTER INSERT OR UPDATE OR DELETE ON product_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_product_rating();

CREATE TRIGGER trigger_update_seller_rating_from_reviews
    AFTER INSERT OR UPDATE OR DELETE ON product_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_seller_rating_from_reviews();

-- Legacy order rating trigger
CREATE TRIGGER trigger_update_seller_rating
    AFTER INSERT OR UPDATE OF buyer_rating ON orders
    FOR EACH ROW
    WHEN (NEW.buyer_rating IS NOT NULL)
    EXECUTE FUNCTION update_seller_rating();

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================

-- Users table comments
COMMENT ON COLUMN users.agreed_to_terms IS 'Whether user agreed to Terms of Service and Privacy Policy';
COMMENT ON COLUMN users.agreed_at IS 'Timestamp when user agreed to terms';

-- Orders table comments
COMMENT ON COLUMN orders.seller_delivery_proof_url IS 'URL of image proof uploaded by seller when marking order as ready/delivered';
COMMENT ON COLUMN orders.buyer_delivery_proof_url IS 'URL of image proof uploaded by buyer when confirming receipt';
COMMENT ON COLUMN orders.buyer_rating IS 'Rating given by buyer (1-5 stars) after order completion (Legacy)';
COMMENT ON COLUMN orders.buyer_rating_comment IS 'Optional comment from buyer about the order (Legacy)';
COMMENT ON COLUMN orders.buyer_rated_at IS 'Timestamp when buyer submitted rating (Legacy)';

-- Product reviews table comments
COMMENT ON TABLE product_reviews IS 'Individual product reviews from buyers for specific order items';
COMMENT ON COLUMN product_reviews.rating IS 'Rating given by buyer (1-5 stars) for the product';
COMMENT ON COLUMN product_reviews.comment IS 'Optional review comment from buyer';
COMMENT ON COLUMN products.average_rating IS 'Average rating from all product reviews';
COMMENT ON COLUMN products.total_reviews IS 'Total number of reviews for this product';

-- Message optimization comments
COMMENT ON INDEX idx_messages_order_id IS 'Improves message retrieval by order';
COMMENT ON INDEX idx_messages_order_created IS 'Optimizes ordering messages within an order';
COMMENT ON INDEX idx_messages_sender_id IS 'Speeds up sender-based queries';
COMMENT ON INDEX idx_messages_unread_sender IS 'Optimizes unread message count queries';
COMMENT ON INDEX idx_messages_created_at IS 'Improves time-based message queries';
COMMENT ON FUNCTION get_unread_counts_by_orders IS 'Efficiently calculates unread counts for multiple orders';

-- ============================================================================
-- DATA MIGRATIONS
-- ============================================================================

-- Update existing users to have agreed_to_terms = TRUE (grandfathered users)
-- This runs only if there are existing users without terms agreement
UPDATE users 
SET agreed_to_terms = TRUE,
    agreed_at = created_at
WHERE agreed_to_terms = FALSE;

-- Update table statistics for better query planning
ANALYZE messages;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE 'AgriMarket Consolidated Database Schema - Created Successfully!';
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE 'Features included:';
    RAISE NOTICE '  ✓ Complete database schema with all tables';
    RAISE NOTICE '  ✓ Product reviews and rating system';
    RAISE NOTICE '  ✓ Product views tracking';
    RAISE NOTICE '  ✓ Delivery proof image fields';
    RAISE NOTICE '  ✓ Order ratings (legacy)';
    RAISE NOTICE '  ✓ Terms agreement tracking';
    RAISE NOTICE '  ✓ Optimized message indexes';
    RAISE NOTICE '  ✓ All indexes and performance improvements';
    RAISE NOTICE '  ✓ Triggers for auto-updates';
    RAISE NOTICE '  ✓ Functions for rating calculations';
    RAISE NOTICE '';
    RAISE NOTICE 'Ready for production deployment!';
    RAISE NOTICE '════════════════════════════════════════════════════════════';
END $$;