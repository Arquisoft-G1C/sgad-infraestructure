// Crea collections y datos iniciales para NoSQL

// Conectar a la base de datos
db = db.getSiblingDB('sgad_nosql');

// ====================
// COLLECTION: processing_logs
// Logs de procesamiento de archivos CSV/Excel
// ====================
db.createCollection('processing_logs', {
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
        uploadedBy: { bsonType: "string" }
      }
    }
  }
});

// ====================
// COLLECTION: notifications
// Notificaciones del sistema
// ====================
db.createCollection('notifications', {
  validator: {
    $jsonSchema: {
      bsonType: "object", 
      required: ["userId", "type", "message", "createdAt"],
      properties: {
        userId: { bsonType: "string" },
        type: { enum: ["assignment", "invoice", "reminder", "system"] },
        message: { bsonType: "string" },
        title: { bsonType: "string" },
        read: { bsonType: "bool" },
        createdAt: { bsonType: "date" },
        metadata: { bsonType: "object" }
      }
    }
  }
});

// ====================
// COLLECTION: invoice_documents
// Documentos de facturas generadas
// ====================
db.createCollection('invoice_documents', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["refereeId", "period", "generatedAt"],
      properties: {
        refereeId: { bsonType: "string" },
        period: { 
          bsonType: "object",
          required: ["year", "month"],
          properties: {
            year: { bsonType: "int" },
            month: { bsonType: "int" }
          }
        },
        totalAmount: { bsonType: "decimal" },
        matches: { bsonType: "array" },
        pdfPath: { bsonType: "string" },
        qrCode: { bsonType: "string" },
        bankDetails: { bsonType: "object" },
        status: { enum: ["generated", "sent", "paid"] },
        generatedAt: { bsonType: "date" },
        paidAt: { bsonType: "date" }
      }
    }
  }
});

// ====================
// COLLECTION: audit_logs
// Logs de auditoría del sistema
// ====================
db.createCollection('audit_logs', {
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
        timestamp: { bsonType: "date" }
      }
    }
  }
});

// ====================
// COLLECTION: system_configuration
// Configuraciones del sistema
// ====================
db.createCollection('system_configuration', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["key", "value"],
      properties: {
        key: { bsonType: "string" },
        value: { bsonType: ["string", "object", "array", "bool", "int", "decimal"] },
        description: { bsonType: "string" },
        updatedAt: { bsonType: "date" },
        updatedBy: { bsonType: "string" }
      }
    }
  }
});

// ====================
// ÍNDICES para Performance
// ====================

// Índices para processing_logs
db.processing_logs.createIndex({ "filename": 1 });
db.processing_logs.createIndex({ "status": 1 });
db.processing_logs.createIndex({ "processedAt": -1 });

// Índices para notifications
db.notifications.createIndex({ "userId": 1 });
db.notifications.createIndex({ "read": 1 });
db.notifications.createIndex({ "createdAt": -1 });
db.notifications.createIndex({ "type": 1 });

// Índices para invoice_documents
db.invoice_documents.createIndex({ "refereeId": 1 });
db.invoice_documents.createIndex({ "period.year": 1, "period.month": 1 });
db.invoice_documents.createIndex({ "status": 1 });
db.invoice_documents.createIndex({ "generatedAt": -1 });

// Índices para audit_logs
db.audit_logs.createIndex({ "userId": 1 });
db.audit_logs.createIndex({ "action": 1 });
db.audit_logs.createIndex({ "timestamp": -1 });
db.audit_logs.createIndex({ "entityType": 1, "entityId": 1 });

// Índices para system_configuration
db.system_configuration.createIndex({ "key": 1 }, { unique: true });

// ====================
// DATOS INICIALES
// ====================

// Configuraciones iniciales del sistema
db.system_configuration.insertMany([
  {
    key: "eligibility_period_months",
    value: 6,
    description: "Meses que debe pasar para que un árbitro pueda dirigir el mismo equipo",
    updatedAt: new Date(),
    updatedBy: "system"
  },
  {
    key: "notification_settings",
    value: {
      email_enabled: true,
      sms_enabled: false,
      push_enabled: true,
      assignment_notification: true,
      invoice_notification: true,
      reminder_hours: [24, 2]
    },
    description: "Configuraciones de notificaciones del sistema",
    updatedAt: new Date(),
    updatedBy: "system"
  },
  {
    key: "billing_settings",
    value: {
      currency: "COP",
      qr_bank: "bancolombia",
      invoice_due_days: 30,
      late_fee_percentage: 0.02
    },
    description: "Configuraciones de facturación",
    updatedAt: new Date(),
    updatedBy: "system"
  }
]);

// Notificaciones de ejemplo
db.notifications.insertMany([
  {
    userId: "admin@sgad.com",
    type: "system",
    title: "Sistema Inicializado",
    message: "El sistema SGAD ha sido inicializado correctamente",
    read: false,
    createdAt: new Date(),
    metadata: {
      priority: "low",
      category: "system"
    }
  }
]);

// Log de auditoría inicial
db.audit_logs.insertOne({
  action: "database_initialization",
  userId: "system",
  entityType: "database",
  entityId: "sgad_nosql",
  changes: {
    collections_created: ["processing_logs", "notifications", "invoice_documents", "audit_logs", "system_configuration"]
  },
  ipAddress: "localhost",
  userAgent: "MongoDB Shell",
  timestamp: new Date()
});

print("SGAD MongoDB collections created successfully!");
print("Collections: " + db.getCollectionNames().join(", "));