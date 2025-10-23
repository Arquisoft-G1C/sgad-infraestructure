// =====================================================
// certificados_db - Referee Certificates & Documents Database
// =====================================================
// This NoSQL database stores certificates, documents, and logs
// for the Referee Management Service

// Conectar a la base de datos certificados
db = db.getSiblingDB("certificados_db");

// ====================
// COLLECTION: certificates
// Certificados y licencias de árbitros
// ====================
db.createCollection("certificates", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["refereeId", "certificateType", "issuedDate"],
      properties: {
        refereeId: { bsonType: "string" },
        certificateType: {
          enum: ["license", "medical", "training", "insurance", "other"],
        },
        certificateNumber: { bsonType: "string" },
        issuedDate: { bsonType: "date" },
        expiryDate: { bsonType: "date" },
        issuingAuthority: { bsonType: "string" },
        documentUrl: { bsonType: "string" },
        status: {
          enum: ["active", "expired", "revoked", "pending"],
        },
        metadata: { bsonType: "object" },
        createdAt: { bsonType: "date" },
        updatedAt: { bsonType: "date" },
      },
    },
  },
});

// ====================
// COLLECTION: referee_documents
// Documentos administrativos de árbitros
// ====================
db.createCollection("referee_documents", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["refereeId", "documentType", "uploadedAt"],
      properties: {
        refereeId: { bsonType: "string" },
        documentType: {
          enum: ["id_card", "contract", "tax_form", "bank_info", "other"],
        },
        fileName: { bsonType: "string" },
        fileUrl: { bsonType: "string" },
        fileSize: { bsonType: "int" },
        mimeType: { bsonType: "string" },
        uploadedAt: { bsonType: "date" },
        uploadedBy: { bsonType: "string" },
        description: { bsonType: "string" },
        tags: { bsonType: "array" },
      },
    },
  },
});

// ====================
// COLLECTION: processing_logs
// Logs de procesamiento de archivos CSV/Excel
// ====================
db.createCollection("processing_logs", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["filename", "status", "processedAt"],
      properties: {
        filename: { bsonType: "string" },
        status: { enum: ["success", "error", "processing"] },
        processedAt: { bsonType: "date" },
        recordsProcessed: { bsonType: "int" },
        errors: { bsonType: "array" },
        uploadedBy: { bsonType: "string" },
        processingTime: { bsonType: "int" },
      },
    },
  },
});

// ====================
// COLLECTION: audit_logs
// Logs de auditoría del sistema
// ====================
db.createCollection("audit_logs", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["action", "userId", "timestamp"],
      properties: {
        action: { bsonType: "string" },
        userId: { bsonType: "string" },
        entityType: { bsonType: "string" },
        entityId: { bsonType: "string" },
        changes: { bsonType: "object" },
        ipAddress: { bsonType: "string" },
        userAgent: { bsonType: "string" },
        timestamp: { bsonType: "date" },
      },
    },
  },
});

// ====================
// COLLECTION: notifications
// Notificaciones del sistema
// ====================
db.createCollection("notifications", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["userId", "type", "message", "createdAt"],
      properties: {
        userId: { bsonType: "string" },
        type: {
          enum: [
            "assignment",
            "certificate_expiry",
            "document_required",
            "system",
          ],
        },
        message: { bsonType: "string" },
        title: { bsonType: "string" },
        read: { bsonType: "bool" },
        createdAt: { bsonType: "date" },
        metadata: { bsonType: "object" },
      },
    },
  },
});

// ====================
// ÍNDICES para Performance
// ====================

// Índices para certificates
db.certificates.createIndex({ refereeId: 1 });
db.certificates.createIndex({ certificateType: 1 });
db.certificates.createIndex({ status: 1 });
db.certificates.createIndex({ expiryDate: 1 });
db.certificates.createIndex(
  { certificateNumber: 1 },
  { unique: true, sparse: true }
);

// Índices para referee_documents
db.referee_documents.createIndex({ refereeId: 1 });
db.referee_documents.createIndex({ documentType: 1 });
db.referee_documents.createIndex({ uploadedAt: -1 });
db.referee_documents.createIndex({ tags: 1 });

// Índices para processing_logs
db.processing_logs.createIndex({ filename: 1 });
db.processing_logs.createIndex({ status: 1 });
db.processing_logs.createIndex({ processedAt: -1 });

// Índices para audit_logs
db.audit_logs.createIndex({ userId: 1 });
db.audit_logs.createIndex({ action: 1 });
db.audit_logs.createIndex({ timestamp: -1 });
db.audit_logs.createIndex({ entityType: 1, entityId: 1 });

// Índices para notifications
db.notifications.createIndex({ userId: 1 });
db.notifications.createIndex({ read: 1 });
db.notifications.createIndex({ createdAt: -1 });
db.notifications.createIndex({ type: 1 });

// ====================
// DATOS INICIALES
// ====================

// Certificados de ejemplo
db.certificates.insertMany([
  {
    refereeId: "example-referee-id-001",
    certificateType: "license",
    certificateNumber: "LIC-2024-001",
    issuedDate: new Date("2024-01-15"),
    expiryDate: new Date("2025-01-15"),
    issuingAuthority: "Federación Colombiana de Fútbol",
    status: "active",
    metadata: {
      level: "nacional",
      sport: "futbol",
    },
    createdAt: new Date(),
    updatedAt: new Date(),
  },
]);

// Notificaciones de ejemplo
db.notifications.insertMany([
  {
    userId: "admin@sgad.com",
    type: "system",
    title: "Sistema Inicializado",
    message:
      "La base de datos certificados_db ha sido inicializada correctamente",
    read: false,
    createdAt: new Date(),
    metadata: {
      priority: "low",
      category: "system",
    },
  },
]);

// Log de auditoría inicial
db.audit_logs.insertOne({
  action: "database_initialization",
  userId: "system",
  entityType: "database",
  entityId: "certificados_db",
  changes: {
    collections_created: [
      "certificates",
      "referee_documents",
      "processing_logs",
      "audit_logs",
      "notifications",
    ],
  },
  ipAddress: "localhost",
  userAgent: "MongoDB Shell",
  timestamp: new Date(),
});

print("=====================================================");
print("certificados_db initialized successfully!");
print("Collections: " + db.getCollectionNames().join(", "));
print("=====================================================");
